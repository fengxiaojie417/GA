%% create_simulink_model.m - 自动创建Simulink仿真模型
% 功能：生成my_tank_model.slx文件

clear; clc; close all;

fprintf('========================================\n');
fprintf('创建Simulink仿真模型\n');
fprintf('========================================\n\n');

%% 1. 创建新模型
modelName = 'my_tank_model';

% 如果模型已存在，先关闭
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if exist([modelName '.slx'], 'file')
    delete([modelName '.slx']);
end

% 创建新系统
new_system(modelName);
open_system(modelName);

fprintf('✓ 创建新模型: %s\n', modelName);

%% 2. 设置仿真参数
set_param(modelName, 'StopTime', '100');
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'Solver', 'ode45');

%% 3. 添加主要模块

% 设定值 (阶跃输入)
add_block('simulink/Sources/Step', [modelName '/Setpoint']);
set_param([modelName '/Setpoint'], 'Time', '0', 'After', '1', 'Position', [50 100 80 130]);

% 控制切换开关
add_block('simulink/Signal Routing/Switch', [modelName '/Control_Switch']);
set_param([modelName '/Control_Switch'], 'Threshold', '0.5', 'Position', [700 100 730 130]);

% 被控对象 (双容水箱传递函数 - 简化版)
add_block('simulink/Continuous/Transfer Fcn', [modelName '/Tank_System']);
set_param([modelName '/Tank_System'], ...
    'Numerator', '[1]', ...
    'Denominator', '[25 10 1]', ...  % 可根据实际系统调整
    'Position', [800 100 900 140]);

% 示波器
add_block('simulink/Sinks/Scope', [modelName '/Scope']);
set_param([modelName '/Scope'], 'Position', [1000 95 1030 145]);

fprintf('✓ 主要模块添加完成\n');

%% 4. 创建常规PID控制器分支
add_block('simulink/Continuous/PID Controller', [modelName '/Conventional_PID']);
set_param([modelName '/Conventional_PID'], ...
    'P', '5', 'I', '0.5', 'D', '1', ...  % 基准参数，可用pidtune调整
    'Position', [500 150 550 190]);

% 误差计算1
add_block('simulink/Math Operations/Sum', [modelName '/Error1']);
set_param([modelName '/Error1'], 'Inputs', '+-', 'Position', [400 155 420 175]);

fprintf('✓ 常规PID分支创建完成\n');

%% 5. 创建模糊PID子系统
subsysName = [modelName '/FuzzyPID_Subsystem'];
add_block('built-in/Subsystem', subsysName);
set_param(subsysName, 'Position', [500 50 600 100]);

% 打开子系统进行编辑
Simulink.SubSystem.deleteContents(subsysName);

% 输入输出端口
add_block('simulink/Sources/In1', [subsysName '/Setpoint_In']);
set_param([subsysName '/Setpoint_In'], 'Position', [50 50 80 70]);

add_block('simulink/Sources/In1', [subsysName '/Feedback_In']);
set_param([subsysName '/Feedback_In'], 'Position', [50 150 80 170]);

add_block('simulink/Sinks/Out1', [subsysName '/Control_Out']);
set_param([subsysName '/Control_Out'], 'Position', [1100 100 1130 120]);

% 误差计算
add_block('simulink/Math Operations/Sum', [subsysName '/Error_Calc']);
set_param([subsysName '/Error_Calc'], 'Inputs', '+-', 'Position', [150 55 170 75]);

% 误差变化率 (微分)
add_block('simulink/Continuous/Derivative', [subsysName '/Error_Rate']);
set_param([subsysName '/Error_Rate'], 'Position', [200 110 230 140]);

% 量化因子
add_block('simulink/Math Operations/Gain', [subsysName '/Ke']);
set_param([subsysName '/Ke'], 'Gain', '1', 'Position', [250 50 280 80]);

add_block('simulink/Math Operations/Gain', [subsysName '/Kec']);
set_param([subsysName '/Kec'], 'Gain', '1', 'Position', [250 110 280 140]);

% 模糊控制器
add_block('fuzblock/Fuzzy Logic Controller', [subsysName '/Fuzzy_Controller']);
set_param([subsysName '/Fuzzy_Controller'], ...
    'FisFile', 'FuzzyPID.fis', ...
    'Position', [350 70 450 130]);

% 比例因子
add_block('simulink/Math Operations/Gain', [subsysName '/K_dkp']);
set_param([subsysName '/K_dkp'], 'Gain', '1', 'Position', [500 40 530 70]);

add_block('simulink/Math Operations/Gain', [subsysName '/K_dki']);
set_param([subsysName '/K_dki'], 'Gain', '1', 'Position', [500 95 530 125]);

add_block('simulink/Math Operations/Gain', [subsysName '/K_dkd']);
set_param([subsysName '/K_dkd'], 'Gain', '1', 'Position', [500 150 530 180]);

% PID基准值
add_block('simulink/Sources/Constant', [subsysName '/Kp_base']);
set_param([subsysName '/Kp_base'], 'Value', '5', 'Position', [600 20 630 50]);

add_block('simulink/Sources/Constant', [subsysName '/Ki_base']);
set_param([subsysName '/Ki_base'], 'Value', '0.5', 'Position', [600 95 630 125]);

add_block('simulink/Sources/Constant', [subsysName '/Kd_base']);
set_param([subsysName '/Kd_base'], 'Value', '1', 'Position', [600 170 630 200]);

% 参数计算 (Sum)
add_block('simulink/Math Operations/Sum', [subsysName '/Kp_Calc']);
set_param([subsysName '/Kp_Calc'], 'Inputs', '++', 'Position', [680 35 700 55]);

add_block('simulink/Math Operations/Sum', [subsysName '/Ki_Calc']);
set_param([subsysName '/Ki_Calc'], 'Inputs', '++', 'Position', [680 100 700 120]);

add_block('simulink/Math Operations/Sum', [subsysName '/Kd_Calc']);
set_param([subsysName '/Kd_Calc'], 'Inputs', '++', 'Position', [680 165 700 185]);

% 外部PID控制器
add_block('simulink/Continuous/PID Controller', [subsysName '/PID_External']);
set_param([subsysName '/PID_External'], ...
    'Controller', 'PID', ...
    'P', '1', 'I', '1', 'D', '1', ...
    'Position', [950 80 1000 140]);

% 设置PID为外部参数模式 (需要在实际使用时手动调整)
% set_param([subsysName '/PID_External'], 'Source', 'external');

fprintf('✓ 模糊PID子系统创建完成\n');

%% 6. 连接信号线 (主模型)

% 设定值到误差计算
add_line(modelName, 'Setpoint/1', 'Error1/1', 'autorouting', 'on');
add_line(modelName, 'Setpoint/1', 'FuzzyPID_Subsystem/1', 'autorouting', 'on');

% PID控制器到开关
add_line(modelName, 'Conventional_PID/1', 'Control_Switch/1', 'autorouting', 'on');
add_line(modelName, 'FuzzyPID_Subsystem/1', 'Control_Switch/3', 'autorouting', 'on');

% 开关到被控对象
add_line(modelName, 'Control_Switch/1', 'Tank_System/1', 'autorouting', 'on');

% 被控对象到示波器和反馈
add_line(modelName, 'Tank_System/1', 'Scope/1', 'autorouting', 'on');

% 创建反馈线 (需要分支)
add_block('simulink/Signal Routing/Goto', [modelName '/Feedback_Goto']);
set_param([modelName '/Feedback_Goto'], 'GotoTag', 'H2_Feedback', 'Position', [950 105 1000 125]);
add_line(modelName, 'Tank_System/1', 'Feedback_Goto/1', 'autorouting', 'on');

add_block('simulink/Signal Routing/From', [modelName '/Feedback_From1']);
set_param([modelName '/Feedback_From1'], 'GotoTag', 'H2_Feedback', 'Position', [350 160 390 180]);
add_line(modelName, 'Feedback_From1/1', 'Error1/2', 'autorouting', 'on');

add_block('simulink/Signal Routing/From', [modelName '/Feedback_From2']);
set_param([modelName '/Feedback_From2'], 'GotoTag', 'H2_Feedback', 'Position', [450 70 490 90]);
add_line(modelName, 'Feedback_From2/1', 'FuzzyPID_Subsystem/2', 'autorouting', 'on');

fprintf('✓ 主模型信号连接完成\n');

%% 7. 连接信号线 (子系统)

% 内部连接
add_line(subsysName, 'Setpoint_In/1', 'Error_Calc/1', 'autorouting', 'on');
add_line(subsysName, 'Feedback_In/1', 'Error_Calc/2', 'autorouting', 'on');

add_line(subsysName, 'Error_Calc/1', 'Ke/1', 'autorouting', 'on');
add_line(subsysName, 'Error_Calc/1', 'Error_Rate/1', 'autorouting', 'on');
add_line(subsysName, 'Error_Rate/1', 'Kec/1', 'autorouting', 'on');

add_line(subsysName, 'Ke/1', 'Fuzzy_Controller/1', 'autorouting', 'on');
add_line(subsysName, 'Kec/1', 'Fuzzy_Controller/2', 'autorouting', 'on');

add_line(subsysName, 'Fuzzy_Controller/1', 'K_dkp/1', 'autorouting', 'on');
add_line(subsysName, 'Fuzzy_Controller/2', 'K_dki/1', 'autorouting', 'on');
add_line(subsysName, 'Fuzzy_Controller/3', 'K_dkd/1', 'autorouting', 'on');

add_line(subsysName, 'K_dkp/1', 'Kp_Calc/2', 'autorouting', 'on');
add_line(subsysName, 'K_dki/1', 'Ki_Calc/2', 'autorouting', 'on');
add_line(subsysName, 'K_dkd/1', 'Kd_Calc/2', 'autorouting', 'on');

add_line(subsysName, 'Kp_base/1', 'Kp_Calc/1', 'autorouting', 'on');
add_line(subsysName, 'Ki_base/1', 'Ki_Calc/1', 'autorouting', 'on');
add_line(subsysName, 'Kd_base/1', 'Kd_Calc/1', 'autorouting', 'on');

add_line(subsysName, 'Error_Calc/1', 'PID_External/1', 'autorouting', 'on');
add_line(subsysName, 'PID_External/1', 'Control_Out/1', 'autorouting', 'on');

fprintf('✓ 子系统信号连接完成\n');

%% 8. 添加数据记录模块

% To Workspace - 误差信号
add_block('simulink/Sinks/To Workspace', [modelName '/Save_Error']);
set_param([modelName '/Save_Error'], ...
    'VariableName', 'error_signal', ...
    'SaveFormat', 'Timeseries', ...
    'Position', [1050 200 1100 230]);

add_block('simulink/Signal Routing/From', [modelName '/Error_Source']);
set_param([modelName '/Error_Source'], 'GotoTag', 'H2_Feedback', 'Position', [950 205 990 225]);

% 创建误差信号
add_block('simulink/Math Operations/Sum', [modelName '/Error_For_Save']);
set_param([modelName '/Error_For_Save'], 'Inputs', '+-', 'Position', [1000 200 1020 220]);
add_line(modelName, 'Setpoint/1', 'Error_For_Save/1', 'autorouting', 'on');
add_line(modelName, 'Error_Source/1', 'Error_For_Save/2', 'autorouting', 'on');
add_line(modelName, 'Error_For_Save/1', 'Save_Error/1', 'autorouting', 'on');

% To Workspace - 时间
add_block('simulink/Sinks/To Workspace', [modelName '/Save_Time']);
set_param([modelName '/Save_Time'], ...
    'VariableName', 'time', ...
    'SaveFormat', 'Array', ...
    'Position', [1050 250 1100 280]);

add_block('simulink/Sources/Clock', [modelName '/Clock']);
set_param([modelName '/Clock'], 'Position', [950 255 980 275]);
add_line(modelName, 'Clock/1', 'Save_Time/1', 'autorouting', 'on');

% To Workspace - 输出信号
add_block('simulink/Sinks/To Workspace', [modelName '/Save_H2']);
set_param([modelName '/Save_H2'], ...
    'VariableName', 'output_H2', ...
    'SaveFormat', 'Timeseries', ...
    'Position', [1050 150 1100 180]);

add_block('simulink/Signal Routing/From', [modelName '/H2_Source']);
set_param([modelName '/H2_Source'], 'GotoTag', 'H2_Feedback', 'Position', [1000 155 1040 175]);
add_line(modelName, 'H2_Source/1', 'Save_H2/1', 'autorouting', 'on');

% To Workspace - 设定值
add_block('simulink/Sinks/To Workspace', [modelName '/Save_Setpoint']);
set_param([modelName '/Save_Setpoint'], ...
    'VariableName', 'setpoint_signal', ...
    'SaveFormat', 'Array', ...
    'Position', [150 100 200 130]);
add_line(modelName, 'Setpoint/1', 'Save_Setpoint/1', 'autorouting', 'on');

fprintf('✓ 数据记录模块添加完成\n');

%% 9. 保存模型
save_system(modelName);
fprintf('\n✓ 模型已保存: %s.slx\n', modelName);

fprintf('\n========================================\n');
fprintf('重要提示:\n');
fprintf('========================================\n');
fprintf('1. 需要手动设置PID_External模块的参数来源为"external"\n');
fprintf('   双击 FuzzyPID_Subsystem/PID_External，\n');
fprintf('   在参数设置中将 Source 改为 "external"\n\n');
fprintf('2. 需要手动连接外部PID参数端口:\n');
fprintf('   Kp_Calc/1 -> PID_External的P端口\n');
fprintf('   Ki_Calc/1 -> PID_External的I端口\n');
fprintf('   Kd_Calc/1 -> PID_External的D端口\n\n');
fprintf('3. 运行前确保 FuzzyPID.fis 文件已创建\n');
fprintf('========================================\n');

close_system(modelName, 0);
fprintf('\n✓ Simulink模型创建完成！\n');
