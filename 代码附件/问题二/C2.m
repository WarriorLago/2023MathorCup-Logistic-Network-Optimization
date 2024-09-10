% 要删除的节点为DC5
TargetPos = 5;
% 加载数据
data1 = load('data1.mat');
data1 = data1.data1;
% 初始化ResultData3
ResultData3 = cell(TotalRoute+1,33);
for i=2:TotalRoute+1
    ResultData3{i,1} = Data_route_detail(i,2);
    ResultData3{i,2} = Data_route_detail(i,3);
end
% 计算每一天的节点流量有向图
for dateIdx = 1:31
    
    % 提取当天的节点流量信息
    s = [];
    t = [];
    for i = 2:size(data1,1)
        if data1{i,2+dateIdx} > 0
            s = [s  data1{i,1}];
            t = [t  data1{i,2}];
        end
    end
    
    
    % 计算目标节点周围的候选节点
    ToPosList_in = CalNearPos(G,TargetPos,0,dateIdx,data1,Data_route_detail);
    ToPosList_out = CalNearPos(G,TargetPos,1,dateIdx,data1,Data_route_detail);
    
    % 模拟退火参数设置
    TemS = 30000; % 初始温度
    CoolRate = 0.99; % 冷却系数
    DiffMax = 0.005; % 允许的误差
    TemE = 1; % 结束的温度
    P1 = 0.15; % 分流比例
    P2 = 20; % 权重上限
    P3 = 0.5; % 每次扰动比例
    
    % 选择候选节点并随机初始化权重
    if isempty(ToPosList_in)
        StartVal{1} = [];
    else
        slectPosList_in = ToPosList_in(1:max(1,round(P1*size(ToPosList_in,1))),1);
        StartVal{1} = CreateRand(1,length(slectPosList_in),P2);
    end
    if isempty(ToPosList_out)
        StartVal{2} = [];
    else
        slectPosList_out = ToPosList_out(1:max(1,round(P1*size(ToPosList_out,1))),1);
        StartVal{2} = CreateRand(1,length(slectPosList_out),P2);
    end
    
    % 初始化温度、解、目标值以及最优值列表
    Solution0 = StartVal;
    TemN = TemS;
    [Result, VC] = CalValue(G, StartVal, TargetPos, dateIdx, ToPosList_in, ToPosList_out, data1, Data_route_detail);
    BEST_VAL_List = [];
    totalCount = 0;
    
    % 降温过程
    while TemN >= TemE
        
        % 等温过程
        while true
            
            % 扰动当前解
            Solution1 = Disturb(Solution0, P2, P3);
            
            % 计算扰动前后的目标值
            [Result0, VC0] = CalValue(G, Solution0, TargetPos, dateIdx, ToPosList_in, ToPosList_out, data1, Data_route_detail);
            [Result1, VC1] = CalValue(G, Solution1, TargetPos, dateIdx, ToPosList_in, ToPosList_out, data1, Data_route_detail);
            diff0 = Result1 - Result0;
            diff = diff0 / (Result0 + 1e-7);
            
            totalCount = totalCount + 1;
            
            % 若达到平衡则退出等温过程，降温
            if abs(diff) < DiffMax
                break;
            % 否则以退火准则接受新解
            elseif diff < 0 || rand < exp(-diff0 / TemN)
                Solution0 = Solution1;
            end
            
        end
        
        % 更新温度、目标值以及最优值列表
        TemN = TemN * CoolRate;
        BEST_VAL_List = [BEST_VAL_List, Result1];
        
        % 若已达到结束温度则结束降温
        if TemN < TemE
            break;
        end
        
    end
    
end
[BEST_VAL,BESTVC] = CalculateValue(G, Solution0, TargetPos, timeidx, ToPosList_in, ToPosList_out, data1, Data_route_detail); % 计算最终总距离
ResultData3(:, kkk + 2) = BESTVC{3};
ResultData3{1, kkk + 2} = datestr(738886 + dateIdx, 'yyyy/mm/dd');
%% 显示替换后结果
if dateIdx == 1
    figure(2)
    s = [];
    t = [];
    for i = 2:size(data1, 1)
        if data1{i, 2 + dateIdx} > 0 && data1{i, 1} ~= TargetPos && data1{i, 2} ~= TargetPos
            s = [s  data1{i, 1}];
            t = [t  data1{i, 2}];
        end
    end
    G = digraph(s, t);
    h = plot(G);
    title([datestr(738886 + dateIdx, 'yyyy/mm/dd') '各节点流量有向图(删去DC' num2str(TargetPos) ')']);
    % [eid,nid] = outedges(G,5);
    % [eid2,nid2] = inedges(G,5);
    highlight(h, ToPosList_in(1:length(StartVal{1}), 1)', 'NodeColor', 'red', 'MarkerSize', 5);
    highlight(h, ToPosList_out(1:length(StartVal{2}), 1)', 'NodeColor', 'green', 'MarkerSize', 5);
    % highlight(h,'Edges',eid,'EdgeColor','g','LineWidth',2);
    % highlight(h,'Edges',eid2,'EdgeColor','r','LineWidth',2);
    BESTVC{3}{1} = 0;
    valout1 = sum(cell2mat(BESTVC{3}));
    valout2 = sum(Data_route_detail(:, 5)) - Data_route_detail(1, 5);
    fprintf(['全路网负荷量'  num2str(valout1 / valout2 * 100) '\n' ]);
end
%% 保存结果数据
ResultData4 = ResultData3(1, :);
idx4 = 2;
for i = 2:TotalRoute + 1
    if ResultData3{i, 1} ~= 5 && ResultData3{i, 2} ~= 5
        ResultData4(idx4, :) = ResultData3(i, :);
        idx4 = idx4 + 1;
    end
end
ResultData4{1, 1} = '站点1';
ResultData4{1, 2} = '站点2';
new_file = ['23年1月删除DC' num2str(TargetPos) '后所有路线数据.xlsx'];
xlswrite(new_file, ResultData4); % 将结果写入excel文件
fprintf(['数据已经保存在 ' new_file '文件中。\n']);
%% 函数部分
function targetList = CalculateNearbyPos(G, idx, isout, timeidx, data1, Data_route_detail)
%     targetList = cell(2);
    if isout > 0
        [~, nid] = outedges(G, idx);
    else
        [~, nid] = inedges(G, idx);
    end
    if isempty(nid)
        targetList = [];
        return;
    end
    temp1 = zeros(length(nid), 4);
    for i = 1:length(nid)
        if isout > 0
            routeIDX = idx * 100 + nid(i);
        else
            routeIDX = nid(i) * 100 + idx;
        end
        findResult = find(Data_route_detail(:, 1) == routeIDX);
        if isempty(findResult)
            fprintf("ERROR!\n");
            targetList = [];
            return;
        end
        temp1(i, 1) = nid(i);
        temp1(i, 2) = Data_route_detail(findResult(1), 5);
        temp1(i, 3) = data1{findResult(1), timeidx + 2};
        temp1(i, 4) = temp1(i, 2) - temp1(i, 3);
    end
    temp1s = sortrows(temp1, 4, 'descend');
    targetList = temp1s;
end
% 生成随机的初始解
function temps0 = CreateRand(a,b,P2)
    % P2是概率值，根据概率随机生成一个ab的矩阵
    temps0 = round(P2rand(a,b));
    % 如果生成的矩阵所有元素之和为0，则将所有元素设为1/(ab)
    if(sum(temps0)==0)
        temps0 = ones(a,b)./(ab);
    else
        % 如果不全为0，则将每个元素除以所有元素之和，使它们之和为1
        temps0 = temps0./sum(temps0);
    end
end
% 扰动函数，将解进行扰动
function Solution = Disturb(Solution0,P2,P3)
    % 对解进行扰动，返回扰动后的解
    Solution{1} = Disturb2(Solution0{1},P2,P3);
    Solution{2} = Disturb2(Solution0{2},P2,P3);
end
% 对单个解进行扰动
function Solution = Disturb2(Solution0,P2,P3)
    % 将传入的解赋值给新的变量Solution
    Solution = Solution0;
    if ~isempty(Solution0)
        le = length(Solution0);
        % 对Solution中的每个元素进行遍历
        for i=1:le
           % 以概率P3对Solution的元素进行修改，修改后的值为[0, P2]之间的随机数
           if rand < P3
              Solution0(i) = round(randP2); 
           end
        end
        % 如果修改后的Solution的所有元素之和为0，则将所有元素设为1/le
        if(sum(Solution)==0)
            Solution = ones(1,le)./le;
        else
            % 如果不全为0，则将每个元素除以所有元素之和，使它们之和为1
            Solution = Solution./sum(Solution);
        end
    end
end
% 计算解的价值
function [Result,Vals] = CalValue(G,StartVal,TargetPos,timeidx,ToPosList_in,ToPosList_out,data1,Data_route_detail)
    Result = 0;
    Vals = cell(1,3);%爆仓站点数量,爆仓路线数量
    Vals{1} = 0;
    Vals{2} = 0;
    tempRouteData = data1(:,timeidx+2);
    if ~isempty(StartVal{1})
        totalValIn = sum(ToPosList_in(:,3));
        % 对StartVal{1}中的每个元素进行遍历
        for i=1:length(StartVal{1})
           addVal =  round(totalValIn*StartVal{1}(i));
           % 计算与ToPosList_in(i,1)相邻的点
           targetList1 = CalNearPos(G,ToPosList_in(i,1),0,timeidx,data1,Data_route_detail);
           if ~isempty(targetList1)
               % 对与ToPosList_in(i,1)相邻的每个点进行遍历
               for j = 1:length(targetList1)
                   % 如果目标点不是TargetPos，则对其进行处理
                   if targetList1(j,1) ~= TargetPos
                       routeIDX = targetList1(j,1)*100 + ToPosList_in(i,1);
                       findResult = find(Data_route_detail(:,1)==routeIDX); 
                       if isempty(findResult)
                           % 如果找不到对应的路线，则中断遍历
                           break;
                       end
                       if targetList1(j,4) - addVal > 0
                           % 如果该路线的容量足够，则将该路线的货物量设为addVal
                           tempRouteData{findResult(1),1} = targetList1(j,3) + addVal;
                           addVal = 0;
                           % 中断遍历
                           break;
                       else
                           % 如果该路线的容量不够，则将该路线的货物量设为最大容量
                           temp2 = addVal - targetList1(j,4);
                           addVal = addVal - temp2;
                           tempRouteData{findResult(1),1} = targetList1(j,2);
                       end
                   end
               end
           else
               % 如果找不到可达的点，则加上惩罚值1000
               Result = Result + 1000;
               Vals{1} = Vals{1} + 1;
           end
           % 如果还有剩余的货物，则加上惩罚值，并将路线数量加1
           if addVal > 0
               Result = Result + addVal;
               Vals{2} = Vals{2} + 1;
           end
        end
    end
% 计算总值
totalValOut = sum(ToPosList_out(:,3));
% 判断起始值是否为空
if ~isempty(StartVal{2})
    % 遍历起始值
    for i=1:length(StartVal{2})
        % 计算需要添加的值
        addVal2 =  round(totalValOut*StartVal{2}(i));
        
        % 计算最近的位置
        targetList2 = CalNearPos(G,ToPosList_out(i,1),1,timeidx,data1,Data_route_detail);
        if ~isempty(targetList2)
            % 遍历最近的位置
            for j = 1:length(targetList2)
                % 判断是否为目标位置
                if targetList2(j,1) ~= TargetPos
                    % 计算路线索引
                    routeIDX = targetList2(j,1) + ToPosList_out(i,1)*100;
                    % 查找路线数据
                    findResult = find(Data_route_detail(:,1)==routeIDX);
                    
                    % 判断是否找到路线数据
                    if isempty(findResult)
                        break;
                    end
                    
                    % 判断是否需要添加的值小于该位置的可用值
                    if targetList2(j,4) - addVal2 > 0
                        % 更新路线数据
                        tempRouteData{findResult(1),1} = targetList2(j,3) + addVal2;
                        addVal2 = 0;
                        break;
                    else
                        % 更新添加值，并更新路线数据
                        temp2 = addVal2 - targetList2(j,4);
                        addVal2 = addVal2 - temp2;
                        tempRouteData{findResult(1),1} = targetList2(j,2);
                    end
                end
            end
        else
            % 更新结果值
            Result = Result + 1000;
            Vals{1} = Vals{1} + 1;
        end
        
        % 判断是否还有需要添加的值
        if addVal2 > 0
            % 更新结果值和计数器
            Result = Result + addVal2;
            Vals{2} = Vals{2} + 1;
        end
    end
end
% 更新路线数据
Vals{3} = tempRouteData;