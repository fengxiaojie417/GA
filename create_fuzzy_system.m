%% create_fuzzy_system.m - 自动创建模糊PID控制器
% 功能：生成FuzzyPID.fis文件

clear; clc; close all;

fprintf('========================================\n');
fprintf('创建模糊PID控制器\n');
fprintf('========================================\n\n');

%% 1. 创建Mamdani模糊推理系统
fis = mamfis('Name', 'FuzzyPID');

%% 2. 定义输入变量

% 输入1: e (误差)
fis = addInput(fis, [-1 1], 'Name', 'e');
fis = addMF(fis, 'e', 'trimf', [-1 -1 -0.6], 'Name', 'NB');  % Negative Big
fis = addMF(fis, 'e', 'trimf', [-1 -0.6 -0.2], 'Name', 'NM'); % Negative Medium
fis = addMF(fis, 'e', 'trimf', [-0.6 -0.2 0], 'Name', 'NS');  % Negative Small
fis = addMF(fis, 'e', 'trimf', [-0.2 0 0.2], 'Name', 'Z');    % Zero
fis = addMF(fis, 'e', 'trimf', [0 0.2 0.6], 'Name', 'PS');    % Positive Small
fis = addMF(fis, 'e', 'trimf', [0.2 0.6 1], 'Name', 'PM');    % Positive Medium
fis = addMF(fis, 'e', 'trimf', [0.6 1 1], 'Name', 'PB');      % Positive Big

% 输入2: ec (误差变化率)
fis = addInput(fis, [-1 1], 'Name', 'ec');
fis = addMF(fis, 'ec', 'trimf', [-1 -1 -0.6], 'Name', 'NB');
fis = addMF(fis, 'ec', 'trimf', [-1 -0.6 -0.2], 'Name', 'NM');
fis = addMF(fis, 'ec', 'trimf', [-0.6 -0.2 0], 'Name', 'NS');
fis = addMF(fis, 'ec', 'trimf', [-0.2 0 0.2], 'Name', 'Z');
fis = addMF(fis, 'ec', 'trimf', [0 0.2 0.6], 'Name', 'PS');
fis = addMF(fis, 'ec', 'trimf', [0.2 0.6 1], 'Name', 'PM');
fis = addMF(fis, 'ec', 'trimf', [0.6 1 1], 'Name', 'PB');

fprintf('✓ 输入变量定义完成\n');

%% 3. 定义输出变量

% 输出1: dKp
fis = addOutput(fis, [-1 1], 'Name', 'dKp');
fis = addMF(fis, 'dKp', 'trimf', [-1 -1 -0.6], 'Name', 'NB');
fis = addMF(fis, 'dKp', 'trimf', [-1 -0.6 -0.2], 'Name', 'NM');
fis = addMF(fis, 'dKp', 'trimf', [-0.6 -0.2 0], 'Name', 'NS');
fis = addMF(fis, 'dKp', 'trimf', [-0.2 0 0.2], 'Name', 'Z');
fis = addMF(fis, 'dKp', 'trimf', [0 0.2 0.6], 'Name', 'PS');
fis = addMF(fis, 'dKp', 'trimf', [0.2 0.6 1], 'Name', 'PM');
fis = addMF(fis, 'dKp', 'trimf', [0.6 1 1], 'Name', 'PB');

% 输出2: dKi
fis = addOutput(fis, [-1 1], 'Name', 'dKi');
fis = addMF(fis, 'dKi', 'trimf', [-1 -1 -0.6], 'Name', 'NB');
fis = addMF(fis, 'dKi', 'trimf', [-1 -0.6 -0.2], 'Name', 'NM');
fis = addMF(fis, 'dKi', 'trimf', [-0.6 -0.2 0], 'Name', 'NS');
fis = addMF(fis, 'dKi', 'trimf', [-0.2 0 0.2], 'Name', 'Z');
fis = addMF(fis, 'dKi', 'trimf', [0 0.2 0.6], 'Name', 'PS');
fis = addMF(fis, 'dKi', 'trimf', [0.2 0.6 1], 'Name', 'PM');
fis = addMF(fis, 'dKi', 'trimf', [0.6 1 1], 'Name', 'PB');

% 输出3: dKd
fis = addOutput(fis, [-1 1], 'Name', 'dKd');
fis = addMF(fis, 'dKd', 'trimf', [-1 -1 -0.6], 'Name', 'NB');
fis = addMF(fis, 'dKd', 'trimf', [-1 -0.6 -0.2], 'Name', 'NM');
fis = addMF(fis, 'dKd', 'trimf', [-0.6 -0.2 0], 'Name', 'NS');
fis = addMF(fis, 'dKd', 'trimf', [-0.2 0 0.2], 'Name', 'Z');
fis = addMF(fis, 'dKd', 'trimf', [0 0.2 0.6], 'Name', 'PS');
fis = addMF(fis, 'dKd', 'trimf', [0.2 0.6 1], 'Name', 'PM');
fis = addMF(fis, 'dKd', 'trimf', [0.6 1 1], 'Name', 'PB');

fprintf('✓ 输出变量定义完成\n');

%% 4. 定义模糊规则
% 基于PID整定专家经验的49条规则 (7x7规则表)
% 规则格式: If (e is X) and (ec is Y) then (dKp is Z1) (dKi is Z2) (dKd is Z3)

fprintf('\n添加模糊规则...\n');

% 规则表 (简化版 - 实际应用中需要根据专家经验调整)
% [e, ec, dKp, dKi, dKd, weight, operator]
% 1=NB, 2=NM, 3=NS, 4=Z, 5=PS, 6=PM, 7=PB

rules = [
    % e=NB时
    1 1 7 1 5 1 1;  % e=NB, ec=NB: dKp=PB, dKi=NB, dKd=PS
    1 2 7 1 4 1 1;  % e=NB, ec=NM: dKp=PB, dKi=NB, dKd=Z
    1 3 6 2 3 1 1;  % e=NB, ec=NS: dKp=PM, dKi=NM, dKd=NS
    1 4 6 2 3 1 1;  % e=NB, ec=Z:  dKp=PM, dKi=NM, dKd=NS
    1 5 5 3 3 1 1;  % e=NB, ec=PS: dKp=PS, dKi=NS, dKd=NS
    1 6 4 4 4 1 1;  % e=NB, ec=PM: dKp=Z,  dKi=Z,  dKd=Z
    1 7 4 4 4 1 1;  % e=NB, ec=PB: dKp=Z,  dKi=Z,  dKd=Z
    
    % e=NM时
    2 1 7 1 5 1 1;
    2 2 7 2 5 1 1;
    2 3 6 3 4 1 1;
    2 4 5 3 3 1 1;
    2 5 5 4 3 1 1;
    2 6 4 4 4 1 1;
    2 7 3 5 4 1 1;
    
    % e=NS时
    3 1 6 2 5 1 1;
    3 2 6 2 5 1 1;
    3 3 5 3 4 1 1;
    3 4 5 4 3 1 1;
    3 5 4 4 3 1 1;
    3 6 3 5 3 1 1;
    3 7 3 6 4 1 1;
    
    % e=Z时
    4 1 6 2 5 1 1;
    4 2 5 3 4 1 1;
    4 3 5 4 3 1 1;
    4 4 4 4 3 1 1;
    4 5 3 4 3 1 1;
    4 6 3 5 4 1 1;
    4 7 2 6 5 1 1;
    
    % e=PS时
    5 1 5 3 5 1 1;
    5 2 5 4 4 1 1;
    5 3 4 4 4 1 1;
    5 4 3 5 3 1 1;
    5 5 3 5 3 1 1;
    5 6 2 6 3 1 1;
    5 7 2 7 3 1 1;
    
    % e=PM时
    6 1 5 4 6 1 1;
    6 2 4 4 5 1 1;
    6 3 3 5 5 1 1;
    6 4 3 5 4 1 1;
    6 5 2 6 4 1 1;
    6 6 2 6 3 1 1;
    6 7 1 7 3 1 1;
    
    % e=PB时
    7 1 4 4 6 1 1;
    7 2 4 4 6 1 1;
    7 3 3 5 5 1 1;
    7 4 2 6 5 1 1;
    7 5 2 6 5 1 1;
    7 6 1 7 5 1 1;
    7 7 1 7 7 1 1;
];

fis = addRule(fis, rules);
fprintf('✓ 已添加 %d 条模糊规则\n', size(rules, 1));

%% 5. 保存模糊系统
writeFIS(fis, 'FuzzyPID.fis');
fprintf('\n✓ 模糊系统已保存: FuzzyPID.fis\n');

%% 6. 显示系统信息
fprintf('\n========================================\n');
fprintf('模糊系统信息:\n');
fprintf('========================================\n');
fprintf('输入变量: %d (e, ec)\n', length(fis.Inputs));
fprintf('输出变量: %d (dKp, dKi, dKd)\n', length(fis.Outputs));
fprintf('模糊规则: %d 条\n', length(fis.Rules));
fprintf('推理方法: %s\n', fis.AndMethod);
fprintf('反模糊化: %s\n', fis.DefuzzificationMethod);
fprintf('========================================\n\n');

%% 7. 可选：查看规则表面
fprintf('提示: 运行以下命令查看规则表面:\n');
fprintf('  gensurf(readfis(''FuzzyPID.fis''))\n\n');

fprintf('✓ 模糊系统创建完成！\n');
