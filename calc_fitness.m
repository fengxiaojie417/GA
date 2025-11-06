function fitness = calc_fitness(X)
    % calc_fitness - GA适应度函数
    % 输入: X = [Ke, Kec, K_dkp, K_dki, K_dkd] (1x5向量)
    % 输出: fitness = 适应度值 (越大越好)
    
    % 解包参数
    Ke    = X(1);  % 误差量化因子
    Kec   = X(2);  % 误差变化率量化因子
    K_dkp = X(3);  % Kp调整量比例因子
    K_dki = X(4);  % Ki调整量比例因子
    K_dkd = X(5);  % Kd调整量比例因子
    
    % 参数有效性检查
    if any(X <= 0)
        fitness = -1e9;
        return;
    end
    
    try
        % 将参数设置到Simulink模型中
        % 注意：路径需要与实际模型中的模块路径一致
        modelName = 'my_tank_model';
        
        % 检查模型是否已加载
        if ~bdIsLoaded(modelName)
            load_system(modelName);
        end
        
        % 设置量化因子
        set_param([modelName '/FuzzyPID_Subsystem/Ke'], 'Gain', num2str(Ke));
        set_param([modelName '/FuzzyPID_Subsystem/Kec'], 'Gain', num2str(Kec));
        
        % 设置比例因子
        set_param([modelName '/FuzzyPID_Subsystem/K_dkp'], 'Gain', num2str(K_dkp));
        set_param([modelName '/FuzzyPID_Subsystem/K_dki'], 'Gain', num2str(K_dki));
        set_param([modelName '/FuzzyPID_Subsystem/K_dkd'], 'Gain', num2str(K_dkd));
        
        % 运行仿真
        simOut = sim(modelName, 'StopTime', '100', 'SaveOutput', 'on');
        
        % 获取仿真数据
        % 假设在模型中有 To Workspace 模块保存了 error_signal 和 time
        if isfield(simOut, 'error_signal') && isfield(simOut, 'time')
            t = simOut.time;
            err = simOut.error_signal;
        else
            % 如果没有，尝试从 logsout 获取
            error('请在Simulink模型中添加 To Workspace 模块保存误差信号');
        end
        
        % 数据预处理：确保时间唯一
        [t_unique, ia, ~] = unique(t);
        err_unique = err(ia);
        
        % 计算ITAE (Integral of Time-weighted Absolute Error)
        % ITAE = ∫ t·|e(t)| dt
        itae = trapz(t_unique, t_unique .* abs(err_unique));
        
        % 添加超调惩罚（可选）
        overshoot = max(err_unique) - 0;  % 假设设定值为0
        if overshoot > 0.1
            penalty = overshoot * 10;
        else
            penalty = 0;
        end
        
        % 添加稳态误差惩罚
        steady_state_error = abs(mean(err_unique(end-10:end)));
        
        % 综合性能指标
        total_cost = itae + penalty + steady_state_error * 50;
        
        % GA求最大值，所以取倒数
        if total_cost > 0
            fitness = 1 / total_cost;
        else
            fitness = -1e9;
        end
        
    catch ME
        % 仿真出错时返回极差适应度
        fprintf('仿真出错: %s\n', ME.message);
        fprintf('当前参数: Ke=%.2f, Kec=%.2f, K_dkp=%.2f, K_dki=%.2f, K_dkd=%.2f\n', ...
                Ke, Kec, K_dkp, K_dki, K_dkd);
        fitness = -1e9;
    end
end
