%% plot_results.m - 结果对比与可视化
% 功能：对比GA优化的模糊PID与常规PID的控制效果

clear; clc; close all;

%% 1. 加载优化结果
fprintf('========================================\n');
fprintf('控制效果对比分析\n');
fprintf('========================================\n\n');

if exist('ga_optimization_results.mat', 'file')
    load('ga_optimization_results.mat');
    fprintf('✓ 已加载GA优化结果\n');
    fprintf('  最优参数: [%.4f, %.4f, %.4f, %.4f, %.4f]\n', best_params);
else
    error('未找到优化结果文件！请先运行 run_ga_main.m');
end

%% 2. 加载Simulink模型
modelName = 'my_tank_model';
if ~bdIsLoaded(modelName)
    load_system(modelName);
end

%% 3. 仿真1：GA优化的模糊PID
fprintf('\n正在运行GA优化模糊PID仿真...\n');

% 设置最优参数
set_param([modelName '/FuzzyPID_Subsystem/Ke'], 'Gain', num2str(best_params(1)));
set_param([modelName '/FuzzyPID_Subsystem/Kec'], 'Gain', num2str(best_params(2)));
set_param([modelName '/FuzzyPID_Subsystem/K_dkp'], 'Gain', num2str(best_params(3)));
set_param([modelName '/FuzzyPID_Subsystem/K_dki'], 'Gain', num2str(best_params(4)));
set_param([modelName '/FuzzyPID_Subsystem/K_dkd'], 'Gain', num2str(best_params(5)));

% 切换到模糊PID控制
set_param([modelName '/Control_Switch'], 'Threshold', '0.5');  % 假设使用Switch模块

simOut_Fuzzy = sim(modelName, 'StopTime', '100');

% 提取数据
t_fuzzy = simOut_Fuzzy.output_H2.Time;
H2_fuzzy = simOut_Fuzzy.output_H2.Data;
setpoint = simOut_Fuzzy.setpoint_signal.Data;

fprintf('✓ 模糊PID仿真完成\n');

%% 4. 仿真2：常规PID
fprintf('正在运行常规PID仿真...\n');

% 切换到常规PID控制
set_param([modelName '/Control_Switch'], 'Threshold', '1.5');  

simOut_PID = sim(modelName, 'StopTime', '100');

% 提取数据
t_pid = simOut_PID.output_H2.Time;
H2_pid = simOut_PID.output_H2.Data;

fprintf('✓ 常规PID仿真完成\n');

%% 5. 性能指标计算
fprintf('\n计算性能指标...\n');

% GA-Fuzzy-PID指标
error_fuzzy = setpoint - H2_fuzzy;
[~, idx_fuzzy] = min(abs(t_fuzzy - 10));  % 从10秒开始
rise_time_fuzzy = t_fuzzy(find(H2_fuzzy >= 0.9*setpoint(1), 1));
overshoot_fuzzy = (max(H2_fuzzy) - setpoint(1)) / setpoint(1) * 100;
settling_time_fuzzy = t_fuzzy(find(abs(error_fuzzy(idx_fuzzy:end)) < 0.02*setpoint(1), 1, 'first') + idx_fuzzy - 1);
iae_fuzzy = trapz(t_fuzzy, abs(error_fuzzy));
ise_fuzzy = trapz(t_fuzzy, error_fuzzy.^2);
itae_fuzzy = trapz(t_fuzzy, t_fuzzy .* abs(error_fuzzy));

% 常规PID指标
error_pid = setpoint - H2_pid;
rise_time_pid = t_pid(find(H2_pid >= 0.9*setpoint(1), 1));
overshoot_pid = (max(H2_pid) - setpoint(1)) / setpoint(1) * 100;
settling_time_pid = t_pid(find(abs(error_pid(idx_fuzzy:end)) < 0.02*setpoint(1), 1, 'first') + idx_fuzzy - 1);
iae_pid = trapz(t_pid, abs(error_pid));
ise_pid = trapz(t_pid, error_pid.^2);
itae_pid = trapz(t_pid, t_pid .* abs(error_pid));

%% 6. 绘制对比图
figure('Position', [100, 100, 1200, 800]);

% 子图1: 液位响应曲线
subplot(2, 2, 1);
plot(t_fuzzy, setpoint, 'k--', 'LineWidth', 1.5); hold on;
plot(t_fuzzy, H2_fuzzy, 'r-', 'LineWidth', 2);
plot(t_pid, H2_pid, 'b-', 'LineWidth', 2);
xlabel('时间 (s)'); ylabel('液位 H_2 (m)');
title('液位响应对比');
legend('设定值', 'GA-Fuzzy-PID', '常规PID', 'Location', 'best');
grid on;

% 子图2: 误差曲线
subplot(2, 2, 2);
plot(t_fuzzy, error_fuzzy, 'r-', 'LineWidth', 1.5); hold on;
plot(t_pid, error_pid, 'b-', 'LineWidth', 1.5);
xlabel('时间 (s)'); ylabel('误差 (m)');
title('跟踪误差对比');
legend('GA-Fuzzy-PID', '常规PID', 'Location', 'best');
grid on;

% 子图3: 性能指标柱状图
subplot(2, 2, 3);
metrics = [rise_time_fuzzy, rise_time_pid; ...
           overshoot_fuzzy, overshoot_pid; ...
           settling_time_fuzzy, settling_time_pid];
bar(metrics');
set(gca, 'XTickLabel', {'GA-Fuzzy-PID', '常规PID'});
ylabel('值');
title('关键性能指标');
legend('上升时间(s)', '超调量(%)', '调节时间(s)', 'Location', 'best');
grid on;

% 子图4: 积分指标柱状图
subplot(2, 2, 4);
integral_metrics = [iae_fuzzy, iae_pid; ...
                    ise_fuzzy, ise_pid; ...
                    itae_fuzzy, itae_pid];
bar(integral_metrics');
set(gca, 'XTickLabel', {'GA-Fuzzy-PID', '常规PID'});
ylabel('值');
title('积分性能指标');
legend('IAE', 'ISE', 'ITAE', 'Location', 'best');
grid on;

%% 7. 打印性能对比表
fprintf('\n========================================\n');
fprintf('性能指标对比\n');
fprintf('========================================\n');
fprintf('指标             GA-Fuzzy-PID    常规PID      改善\n');
fprintf('----------------------------------------\n');
fprintf('上升时间(s)      %.4f         %.4f      %.1f%%\n', ...
    rise_time_fuzzy, rise_time_pid, (rise_time_pid-rise_time_fuzzy)/rise_time_pid*100);
fprintf('超调量(%%)        %.2f          %.2f       %.1f%%\n', ...
    overshoot_fuzzy, overshoot_pid, (overshoot_pid-overshoot_fuzzy)/overshoot_pid*100);
fprintf('调节时间(s)      %.4f         %.4f      %.1f%%\n', ...
    settling_time_fuzzy, settling_time_pid, (settling_time_pid-settling_time_fuzzy)/settling_time_pid*100);
fprintf('IAE              %.4f         %.4f      %.1f%%\n', ...
    iae_fuzzy, iae_pid, (iae_pid-iae_fuzzy)/iae_pid*100);
fprintf('ISE              %.4f         %.4f      %.1f%%\n', ...
    ise_fuzzy, ise_pid, (ise_pid-ise_fuzzy)/ise_pid*100);
fprintf('ITAE             %.4f         %.4f      %.1f%%\n', ...
    itae_fuzzy, itae_pid, (itae_pid-itae_fuzzy)/itae_pid*100);
fprintf('========================================\n');

%% 8. 保存图像
saveas(gcf, 'control_comparison.png');
fprintf('\n✓ 对比图已保存: control_comparison.png\n');

close_system(modelName, 0);
