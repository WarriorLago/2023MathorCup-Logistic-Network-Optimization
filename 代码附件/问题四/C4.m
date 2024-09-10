function [result, vals, tempRouteData] = calculateRoute(graph, startVal, dataRouteDetail, timeIdx, resultData2, toPosListOut, targetPos)
    result = 0;
    vals = {0, 0, 0, []};
    tempRouteData = dataRouteDetail(:,3);
    % 新增路线
    Addages = [14,82,300000;36,82,300000;23,82,200000;82,8,300000;82,9,200000;82,10,200000;82,4,200000];
    s = dataRouteDetail(2:end,2);
    t = dataRouteDetail(2:end,3);
    G_all = digraph(s,t);
    highLightEd = [];
    for idx1 = 1:size(Addages,1)
        G_all = G_all.addedge(Addages(idx1,1),Addages(idx1,2));
        highLightEd = [highLightEd,Addages(idx1,1),Addages(idx1,2)];
    end
    % 计算最近的位置并添加其运输能力
    if ~isempty(startVal{2})
        totalValOut = sum(toPosListOut(:,3));
        for i = 1:length(startVal{2})
            addVal = round(totalValOutStartVal{2}(i));
            tempPos = toPosListOut(i,1);
            targetList = calculateNearbyPositions(G_all, tempPos, 1, timeIdx, resultData2, dataRouteDetail); % 使用 G_all 进行计算
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
end