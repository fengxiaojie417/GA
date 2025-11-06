%% run_ga_main.m - 遗传算法优化主程序
% 功能：使用GA优化模糊PID控制器的参数
% 优化参数：[Ke, Kec, K_dkp, K_dki, K_dkd]

clear; clc; close all;

%% 1. 初始化设置
fprintf('========================================\n');
fprintf('GA优化模糊PID控制器 - 开始运行\n');
fprintf('========================================\n\n');

% 加载Simulink模型
modelName = 'my_tank_model';
if ~bdIsLoaded(modelName)
    load_system(modelName);
    fprintf('✓ 已加载Simulink模型: %s\n', modelName);
else
    fprintf('✓ 模型已在内存中\n');
end

%% 2. 设置GA参数
n_vars = 5;  % 优化变量个数 [Ke, Kec, K_dkp, K_dki, K_dkd]

% 参数边界
%           Ke    Kec   K_dkp  K_dki  K_dkd
lb = [     0.1,  0.1,   0.1,   0.1,   0.1 ];  % 下限
ub = [    10.0, 10.0,   5.0,   5.0,   5.0 ];  % 上限

fprintf('\n参数搜索范围:\n');
fprintf('  Ke (误差量化因子):        [%.1f, %.1f]\n', lb(1), ub(1));
fprintf('  Kec (误差变化率量化因子): [%.1f, %.1f]\n', lb(2), ub(2));
fprintf('  K_dkp (Kp比例因子):       [%.1f, %.1f]\n', lb(3), ub(3));
fprintf('  K_dki (Ki比例因子):       [%.1f, %.1f]\n', lb(4), ub(4));
fprintf('  K_dkd (Kd比例因子):       [%.1f, %.1f]\n', lb(5), ub(5));

%% 3. 配置GA选项
options = optimoptions('ga', ...
    'PopulationSize', 30, ...           % 种群大小（减小以加快速度）
    'MaxGenerations', 30, ...           % 最大代数
    'EliteCount', 3, ...                % 精英个体数量
    'CrossoverFraction', 0.8, ...       % 交叉概率
    'FunctionTolerance', 1e-6, ...      % 函数容差
    'MutationFcn', {@mutationadaptfeasible}, ... % 自适应可行变异
    'SelectionFcn', @selectionstochunif, ...     % 随机均匀选择
    'PlotFcn', {@gaplotbestf, @gaplotbestindiv, @gaplotscores}, ... % 绘图函数
    'Display', 'iter', ...              % 每代显示
    'UseParallel', false);              % 如有并行工具箱可改为true

fprintf('\n遗传算法配置:\n');
fprintf('  种群大小: %d\n', options.PopulationSize);
fprintf('  最大代数: %d\n', options.MaxGenerations);
fprintf('  交叉概率: %.1f\n', options.CrossoverFraction);
fprintf('  精英保留: %d\n', options.EliteCount);

%% 4. 运行遗传算法
fprintf('\n========================================\n');
fprintf('开始遗传算法优化...\n');
fprintf('========================================\n');

tic;  % 开始计时

% 执行GA优化
[best_params, best_fitness] = ga(@calc_fitness, n_vars, ...
                                  [], [], [], [], ...  % 无线性约束
                                  lb, ub, ...          % 边界约束
                                  [], ...              % 无非线性约束
                                  options);

elapsed_time = toc;  % 结束计时

%% 5. 显示优化结果
fprintf('\n========================================\n');
fprintf('优化完成！\n');
fprintf('========================================\n');
fprintf('总耗时: %.2f 秒 (%.2f 分钟)\n', elapsed_time, elapsed_time/60);
fprintf('\n最优适应度值 (1/ITAE): %.6f\n', best_fitness);
fprintf('估计ITAE值: %.4f\n', 1/best_fitness);
fprintf('\n最优参数:\n');
fprintf('  Ke    = %.4f\n', best_params(1));
fprintf('  Kec   = %.4f\n', best_params(2));
fprintf('  K_dkp = %.4f\n', best_params(3));
fprintf('  K_dki = %.4f\n', best_params(4));
fprintf('  K_dkd = %.4f\n', best_params(5));

%% 6. 保存结果
save('ga_optimization_results.mat', 'best_params', 'best_fitness', 'elapsed_time');
fprintf('\n✓ 结果已保存到: ga_optimization_results.mat\n');

%% 7. 用最优参数进行验证仿真
fprintf('\n正在用最优参数进行验证仿真...\n');

set_param([modelName '/FuzzyPID_Subsystem/Ke'], 'Gain', num2str(best_params(1)));
set_param([modelName '/FuzzyPID_Subsystem/Kec'], 'Gain', num2str(best_params(2)));
set_param([modelName '/FuzzyPID_Subsystem/K_dkp'], 'Gain', num2str(best_params(3)));
set_param([modelName '/FuzzyPID_Subsystem/K_dki'], 'Gain', num2str(best_params(4)));
set_param([modelName '/FuzzyPID_Subsystem/K_dkd'], 'Gain', num2str(best_params(5)));

simOut = sim(modelName, 'StopTime', '100');

fprintf('✓ 验证仿真完成\n');

%% 8. 清理
save_system(modelName);
fprintf('\n✓ 模型已保存\n');

fprintf('\n========================================\n');
fprintf('提示: 运行 plot_results.m 查看对比结果\n');
fprintf('========================================\n');
