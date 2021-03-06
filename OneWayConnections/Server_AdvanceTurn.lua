
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	--result GameOrderAttackTransferResult
	--order GameOrderAttackTransfer
    if (order.proxyType == 'GameOrderAttackTransfer') then
		removedconns = stringtotable(Mod.Settings.RemovedConnections);
		local num = 1;
		local Match = false;
		local Fromterrname = string.upper(game.Map.Territories[order.From].Name);
		local Toterrname = string.upper(game.Map.Territories[order.To].Name);
		while(num < tablelength(removedconns) and Match == false)do
			if(removedconns[num] ~=nil and removedconns[num+1] ~=nil)then
				if(string.upper(removedconns[num]) == Fromterrname and string.upper(removedconns[num+1]) == Toterrname)then
					Match = true;
					skipThisOrder(WL.ModOrderControl.Skip);
				end
			end
			num = num + 2;
		end
	end
end
function stringtotable(variable)
	chartable = {};
	while(string.len(variable)>0)do
		chartable[tablelength(chartable)] = string.sub(variable, 1 , 1);
		variable = string.sub(variable, 2);
	end
	local newtable = {};
	local tablepos = 0;
	local executed = false;
	for _, elem in pairs(chartable)do
		if(elem == ",")then
			tablepos = tablepos + 1;
			newtable[tablepos] = "";
			executed = true;
		else
			if(executed == false)then
				tablepos = tablepos + 1;
				newtable[tablepos] = "";
				executed = true;
			end
			if(newtable[tablepos] == nil)then
				newtable[tablepos] = elem;
			else
				newtable[tablepos] = newtable[tablepos] .. elem;
			end
		end
	end
	return newtable;
end
function tablelength(T)
	local count = 0;
	for _ in pairs(T) do count = count + 1 end;
	return count;
end
