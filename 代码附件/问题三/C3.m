% 要删除的节点为DC5
TargetPos = 9;%要删除的节点
data2 = load('data2.mat');
data2 = data2.data2;
% 初始化ResultData3
ResultData3 = cell(TotalRoute+1,33);
for i=2:TotalRoute+1
    ResultData3{i,1} = Data_route_detail(i,2);
    ResultData3{i,2} = Data_route_detail(i,3);
end
ResultData5 = cell(1,4);
ResultData5(1,:) = {"站点1","站点2","添加时间","流量"};
% 计算每一天的节点流量有向图
for kkk = 1:31       
    dateIdx = kkk;
    s = [];
    t = [];
    for i = 2:size(data2,1)
        if data2{i,2+dateIdx} > 0
            s = [s  data2{i,1}];
            t = [t  data2{i,2}];
        end
    end
    G = digraph(s,t);
    if dateIdx == 1
        figure(1)
        h = plot(G);
        title([datestr(738886 + dateIdx,'yyyy/mm/dd') '各节点流量有向图']);
        [eid,nid] = outedges(G,TargetPos);
        [eid2,nid2] = inedges(G,TargetPos);
        highlight(h,[TargetPos],'NodeColor','red','MarkerSize',5);
        highlight(h,'Edges',eid,'EdgeColor','g','LineWidth',2);
        highlight(h,'Edges',eid2,'EdgeColor','r','LineWidth',2);
    end
    ToPosList_in = CalNearPos(G,TargetPos,0,dateIdx,data2,Data_route_detail);
    ToPosList_out = CalNearPos(G,TargetPos,1,dateIdx,data2,Data_route_detail);
    
% 模拟退火参数设置
initial_temperature = 30000; % 初始温度
cooling_rate = 0.99; % 冷却系数
allowed_error = 0.005; % 允许的误差
end_temperature = 1; % 结束的温度
split_ratio = 0.15; % 分流比例
weight_limit = 20; % 权重上限
perturbation_ratio = 0.5; % 每次扰动比例
time_index = date_index;
% 构造初始解
initial_solution = create_new_solution(to_pos_list_in, to_pos_list_out, weight_limit);
current_solution = initial_solution;
current_temperature = initial_temperature; % 当前温度
% 计算初始数据
[initial_result, vehicle_count] = calculate_value(G, initial_solution, target_pos, time_index, to_pos_list_in, to_pos_list_out, result_data_7, data_route_detail);
best_value_list = [];
best_solution = initial_solution;
total_count = 0;
% 降温过程
while current_temperature >= end_temperature
    % 等温过程
    while true
        % 扰动当前的解
        perturbed_solution = disturb(current_solution, to_pos_list_in, to_pos_list_out, weight_limit, perturbation_ratio);
        % 扰动形成新解与旧解的比较
        [result_current, vehicle_count_current] = calculate_value(G, current_solution, target_pos, time_index, to_pos_list_in, to_pos_list_out, result_data_7, data_route_detail);
        [result_perturbed, vehicle_count_perturbed] = calculate_value(G, perturbed_solution, target_pos, time_index, to_pos_list_in, to_pos_list_out, result_data_7, data_route_detail);
        diff = (result_perturbed - result_current) / (result_current + 1e-7);
        total_count = total_count + 1;
        % 该温度下已经达到了平衡则退出等温过程，降温
        if abs(diff) < allowed_error
            break;
        % 否则以退火准则接受新的最优解
        elseif diff < 0 || rand < exp(- (result_perturbed - result_current) / current_temperature)
            current_solution = perturbed_solution;
        end
        % 如果新解更优，则更新最优解
        if diff < 0
            best_solution = perturbed_solution;
        end
    end
    
    current_temperature = current_temperature * cooling_rate; % 更新温度
    best_value_list = [best_value_list, result_perturbed];
    % 判断是否达到结束温度，结束降温
    if current_temperature < end_temperature
        break;
    end
end
% 计算最优解
[BEST_VAL, BESTVC] = CalValue(G, Solution0, TargetPos, timeidx, ToPosList_in, ToPosList_out, data2, Data_route_detail); 
% 把最优解的某些信息存储到ResultData3中
ResultData3(:, kkk+2) = BESTVC{3};
ResultData3{1, kkk+2} = datestr(738886 + dateIdx, 'yyyy/mm/dd');
% 把最优解新增的边信息存储到ResultData5中
Addages = BESTVC{4};
startLen = size(ResultData5, 1);
for idx1 = 1:size(Addages, 1)
    ResultData5(startLen + idx1, :) = {Addages(idx1, 1), Addages(idx1, 2), ResultData3{1, kkk+2}, Addages(idx1, 3)};        
end
% 显示替换后的结果
if dateIdx == 1        
    figure(2)
    s = [];
    t = [];
    for i = 2:size(data2, 1)
        if BESTVC{3}{i} > 0 &&  data2{i, 1} ~= TargetPos && data2{i, 2} ~= TargetPos
            s = [s, data2{i, 1}];
            t = [t, data2{i, 2}];
        end
    end
    G = digraph(s, t);
    highLightEd = [];
    for idx1 = 1:size(Addages, 1)
        highLightEd = [highLightEd, Addages(idx1, 1), Addages(idx1, 2)];
    end
    
    h = plot(G);
    title([datestr(738886 + dateIdx,'yyyy/mm/dd') '各节点流量有向图(删去DC' num2str(TargetPos)  ')']);
    if ~isempty(ToPosList_in)
        highlight(h, ToPosList_in(1:length(Solution0{1}), 1)', 'NodeColor', 'red', 'MarkerSize', 5);
    end
    if ~isempty(ToPosList_out)
        highlight(h, ToPosList_out(1:length(Solution0{2}), 1)', 'NodeColor', 'green', 'MarkerSize', 5);
    end
    highlight(h, 'Edges', highLightEd, 'EdgeColor', 'black', 'LineWidth', 2);
    BESTVC{3}{1} = 0;
    valout1 = sum(cell2mat(BESTVC{3}));
    valout2 = sum(Data_route_detail(:, 5)) - Data_route_detail(1, 5);
    fprintf(['全路网负荷量'  num2str(valout1/valout2*100) '\n' ]);
end
% 打印进度
fprintf(['进度 ' num2str(kkk/31*100)  '...\n']);
%% 保存结果数据
% 将删除DC后的所有路线数据保存在Excel文件中
ResultData4 = ResultData3(1,:);
idx4 = 2;
for i=2:TotalRoute+1
    if ResultData3{i,1}~=TargetPos && ResultData3{i,2} ~= TargetPos
        ResultData4(idx4,:) = ResultData3(i,:);
        idx4 = idx4 + 1;
    end
end
ResultData4{1,1} = '站点1';
ResultData4{1,2} = '站点2';
fnew = ['23年1月删除DC' num2str(TargetPos)  '后所有路线数据.xlsx'] ;
xlswrite(fnew,ResultData4); % 将数据写进Excel文件中
fprintf(['数据已经保存在 ' fnew '文件中。\n']);
% 将新增路线数据保存在Excel文件中
fnew5 = ['23年1月删除DC' num2str(TargetPos)  '后新增路线数据.xlsx'] ;
xlswrite(fnew5,ResultData5);
fprintf(['新增路线数据已经保存在 ' fnew5 '文件中。\n']);
%% 函数部分
function targetList = CalNearPos(G, idx, isout, timeidx, ResultData2, Data_route_detail)
    % 计算最近的站点
    if isout > 0
        [~,nid] = outedges(G,idx);
    else
        [~,nid] = inedges(G,idx);
    end
    if isempty(nid)
       targetList = [];
       return;
    end
    temp1 = zeros(length(nid),4);    
    
    for i = 1:length(nid)
        if isout > 0
            routeIDX = idx*100 + nid(i);
        else
            routeIDX = nid(i)*100 + idx;
        end
        findResult = find(Data_route_detail(:,1)==routeIDX);
        if isempty(findResult)
            fprintf("ERROR!\n");
            targetList = [];
            return;          
        end
        temp1(i,1) = nid(i);
        temp1(i,2) = Data_route_detail(findResult(1),5);
        temp1(i,3) = ResultData2{findResult(1),timeidx+2};
        temp1(i,4) = temp1(i,2) - temp1(i,3);
    end
    temp1s = sortrows(temp1,4,'descend');
    targetList = temp1s;   
end
function StartVal = CreateNewSolution(ToPosList_in, ToPosList_out, P2)
    % 针对进站点和出站点，创建一个新的解决方案
    P1 = rand;
    if isempty(ToPosList_in)
        StartVal{1} = [];
    else
        selectPosList_in = ToPosList_in(1:max(1,round(P1*size(ToPosList_in,1))),1);
        StartVal{1} = CreateRand(1,length(selectPosList_in),P2);
    end
    if isempty(ToPosList_out)
        StartVal{2} = [];
    else
        selectPosList_out = ToPosList_out(1:max(1,round(P1*size(ToPosList_out,1))),1);
        StartVal{2} = CreateRand(1,length(selectPosList_out),P2);
    end
    StartVal{3} = P1;
end
function temps0 = CreateRand(a,b,P2)
    % 创建一个大小为a*b的随机矩阵
    temps0 = round(P2*rand(a,b));
    % 若所有元素之和等于0，则将所有元素设为1/(a*b)
    if(sum(temps0)==0)
        temps0 = ones(a,b)./(a*b);
    else
        % 将元素值归一化，使得所有元素之和为1
        temps0 = temps0./sum(temps0);
    end
end
function Solution = Disturb(Solution0,ToPosList_in,ToPosList_out,P2,P3)
    % 在ToPosList_in和ToPosList_out中选择部分位置，创建一个新的解决方案
    Solution = CreateNewSolution(ToPosList_in,ToPosList_out,P2);
    % 注释掉的代码未被使用，因此可以删除
%     Soultion{1} = Disturb2(Solution0{1},P2,P3);
%     Soultion{2} = Disturb2(Solution0{2},P2,P3);
end
function Solution = Disturb2(Solution0,P2,P3)
    Solution = Solution0;
    if ~isempty(Solution0)
        le = length(Solution0);
        for i=1:le
           % 以P3的概率，将Solution中的某个元素随机设置为0~P2之间的值
           if rand < P3
              Solution(i) = round(rand*P2); 
           end            
        end
        % 若所有元素之和等于0，则将所有元素设为1/le
        if(sum(Solution)==0)
            Solution = ones(1,le)./le;
        else
            % 将元素值归一化，使得所有元素之和为1
            Solution = Solution./sum(Solution);
        end
    end    
end
function [Result, Vals] = CalValue(G, StartVal, TargetPos, timeidx, ToPosList_in, ToPosList_out, ResultData2, Data_route_detail)
    % 初始化结果和值
    Result = (length(StartVal{1}) + length(StartVal{2})) * 50;
    Vals = cell(1, 4); % {爆仓站点数量,爆仓路线数量}
    Vals{1} = 0;
    Vals{2} = 0;
    
    % 备份路径数据
    tempRouteData = ResultData2(:, timeidx + 2);
    
    % 遍历内部调拨站点
    if ~isempty(StartVal{1})
        % 计算总调拨货物价值
        totalValIn = sum(ToPosList_in(:, 3));
        
        for i = 1:length(StartVal{1})
            % 计算当前站点需要调拨的货物价值
            addVal = round(totalValIn * StartVal{1}(i));
            % 获取当前站点编号
            tempPos1 = ToPosList_in(i, 1);
            % 计算当前站点的周围可达站点列表
            targetList1 = CalNearPos(G, tempPos1, 0, timeidx, ResultData2, Data_route_detail);
            
            % 如果有可达站点
            if ~isempty(targetList1)
                for j = 1:size(targetList1, 1)
                    % 如果可达站点不是目标站点
                    if targetList1(j, 1) ~= TargetPos
                        % 计算当前路线编号
                        routeIDX = targetList1(j, 1) * 100 + tempPos1;
                        % 查找当前路线在数据中的索引
                        findResult = find(Data_route_detail(:, 1) == routeIDX);
                        
                        % 如果找到了对应路线
                        if ~isempty(findResult)
                            % 如果当前站点需要调拨的货物价值小于可达站点的剩余货物价值
                            if targetList1(j, 4) - addVal > 0
                                % 更新路线上的货物价值
                                tempRouteData{findResult(1), 1} = targetList1(j, 3) + addVal;
                                addVal = 0;
                                break;
                            else
                                % 更新剩余的货物价值，并更新路线上的货物价值
                                temp2 = addVal - targetList1(j, 4);
                                addVal = temp2;
                                tempRouteData{findResult(1), 1} = targetList1(j, 2);
                            end
                        else
                            % 如果没有找到对应路线，记录到Vals{4}中
                            Vals{4} = [Vals{4}; targetList1(j, 1), tempPos1, addVal];
                            break;
                        end
                    end
                end
            else
                % 如果当前站点周围没有可达站点，记录到Vals{1}中
                Result = Result + 1000;
                Vals{1} = Vals{1} + 1;
                for mm = 1:81
                    routeIDX = mm * 100 + tempPos1;
                    findResult = find(Data_route_detail(:, 1) == routeIDX);
                    if isempty(findResult)
                        Vals{4} = [Vals{4}; mm, tempPos1, addVal];
                        break;
                    end
                end
            end
            
            % 如果还有剩余的货物价值，记录到Vals{2}中
            if addVal > 0
                Result = Result + addVal;
                Vals{2} = Vals{2} + 1;
            end
        end
    end
end
if ~isempty(startVal{2})
    totalValOut = sum(toPosListOut(:,3));
    for i = 1:length(startVal{2})
        addVal = round(totalValOutStartVal{2}(i));
        tempPos = toPosListOut(i,1);
        targetList = calculateNearbyPositions(graph, tempPos, 1, timeIdx, resultData2, dataRouteDetail);
        if ~isempty(targetList)
            for j = 1:size(targetList, 1)
                if targetList(j,1) ~= targetPos
                    routeIdx = targetList(j,1) + tempPos * 100;
                    findResult = find(dataRouteDetail(:,1)==routeIdx); 
                    if isempty(findResult)
                        break;
                    end
                    if targetList(j,4) - addVal > 0
                        tempRouteData{findResult(1),1} = targetList(j,3) + addVal;
                        addVal = 0;
                        break;
                    else
                        temp = addVal - targetList(j,4);
                        addVal = addVal - temp;
                        tempRouteData{findResult(1),1} = targetList(j,2);
                    end
                end
            end
        else
            result = result + 1000;
            vals{1} = vals{1} + 1;
            for mm = 1:81
                routeIdx = mm + tempPos * 100;
                findResult = find(dataRouteDetail(:,1)==routeIdx);
                if isempty(findResult)
                    vals{4} = [vals{4}; tempPos, mm, addVal];
                    break;
                end
            end
        end
        if addVal > 0
            result = result + addVal;
            vals{2} = vals{2} + 1;
        end
    end
end
vals{3} = tempRouteData;