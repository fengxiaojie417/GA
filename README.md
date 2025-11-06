🚀 完整操作步骤
第一步：创建模糊系统

在MATLAB命令窗口运行：

matlabcreate_fuzzy_system
这会生成 FuzzyPID.fis 文件
第二步：创建Simulink模型

运行：

matlabcreate_simulink_model
这会生成 my_tank_model.slx 文件
⚠️ 重要：需要手动调整的地方

打开 my_tank_model.slx
双击进入 FuzzyPID_Subsystem 子系统
双击 PID_External 模块
在参数设置对话框中：

找到 "Source" 选项
从下拉菜单选择 "external"
点击"OK"



第三步：运行GA优化

确保所有文件都在同一个文件夹，运行：

matlabrun_ga_main

这会开始遗传算法优化（大约需要10-30分钟）
会自动显示进化曲线
结果保存在 ga_optimization_results.mat

第四步：查看结果对比

优化完成后，运行：

matlabplot_results

会生成4个对比图
显示性能指标表
保存图片为 control_comparison.png


📝 文件清单总结
你需要的所有文件都已经生成：
文件名类型说明create_fuzzy_system.mM文件创建模糊系统create_simulink_model.mM文件创建Simulink模型calc_fitness.mM文件GA适应度函数run_ga_main.mM文件GA优化主程序plot_results.mM文件结果对比绘图
生成的文件：

FuzzyPID.fis - 模糊系统（运行步骤1后生成）
my_tank_model.slx - Simulink模型（运行步骤2后生成）
ga_optimization_results.mat - 优化结果（运行步骤3后生成）


⚠️ 常见问题

如果提示找不到 fuzblock：

需要安装 Fuzzy Logic Toolbox


如果仿真出错：

检查模糊系统文件 FuzzyPID.fis 是否存在
检查模型中的模块路径名称是否一致


如果GA运行很慢：

可以减少种群大小和代数（在 run_ga_main.m 中修改）
例如：'PopulationSize', 20, 'MaxGenerations', 20
