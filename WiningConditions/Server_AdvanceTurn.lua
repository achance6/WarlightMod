function Server_AdvanceTurn_Start (game,addNewOrder)
	playerGameData = Mod.PlayerGameData;
end
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if(order.PlayerID == WL.PlayerID.Neutral)then
		return;
	end
	if(order.proxyType == "GameOrderDeploy")then
		if(game.ServerGame.Game.Players[order.PlayerID].IsAI == false)then
			playerGameData[order.PlayerID].Ownedarmies = playerGameData[order.PlayerID].Ownedarmies+order.NumArmies;
			checkwin(order.PlayerID,addNewOrder,game);
		end
	end
	if(order.proxyType == "GameOrderAttackTransfer")then
		if(result.IsAttack)then
			local toowner = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;
			if(result.IsSuccessful)then
				for _,boni in pairs(game.Map.Territories[order.To].PartOfBonuses)do
					local Match = true;
					local Match2 = true;
					for _,terrid in pairs(game.Map.Bonuses[boni].Territories)do
						if(terrid ~= order.To)then
							local terrowner = game.ServerGame.LatestTurnStanding.Territories[terrid].OwnerPlayerID;
							if(terrowner ~= toowner)then
								Match2 = false;
							end
							if(terrowner ~= order.PlayerID)then
								Match = false;
							end
						end
					end
					if(Match == true and game.ServerGame.Game.Players[order.PlayerID].IsAI == false)then
						playerGameData[order.PlayerID].Capturedbonuses = playerGameData[order.PlayerID].Capturedbonuses+1;
						playerGameData[order.PlayerID].Ownedbonuses = playerGameData[order.PlayerID].Ownedbonuses+1;
					end
					if(Match2 == true and toowner ~= WL.PlayerID.Neutral and game.ServerGame.Game.Players[toowner].IsAI == false)then
						playerGameData[toowner].Lostbonuses = playerGameData[toowner].Lostbonuses + 1;
						playerGameData[toowner].Ownedbonuses = playerGameData[toowner].Ownedbonuses - 1;
					end
				end
			end
			if(game.ServerGame.Game.Players[order.PlayerID].IsAI == false)then
				if(result.IsSuccessful)then
					playerGameData[order.PlayerID].Capturedterritories = playerGameData[order.PlayerID].Capturedterritories+1;
					playerGameData[order.PlayerID].Ownedterritories = playerGameData[order.PlayerID].Ownedterritories+1;
					local Match = true;
					for _,terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
						if(terr.OwnerPlayerID == toowner and terr.ID ~= order.To)then
							Match = false;
						end
					end
					if(Match == true)then
						if(toowner ~= WL.PlayerID.Neutral and game.ServerGame.Game.Players[toowner].IsAI == false)then
							playerGameData[order.PlayerID].Eleminateplayers = playerGameData[order.PlayerID].Eleminateplayers+1;
						else
							playerGameData[order.PlayerID].Eleminateais = playerGameData[order.PlayerID].Eleminateais+1;
						end
						playerGameData[order.PlayerID].Eleminateaisandplayers = playerGameData[order.PlayerID].Eleminateaisandplayers+1;
					end
				end
				playerGameData[order.PlayerID].Lostarmies = playerGameData[order.PlayerID].Lostarmies+result.AttackingArmiesKilled.NumArmies;
				playerGameData[order.PlayerID].Killedarmies = playerGameData[order.PlayerID].Killedarmies+result.DefendingArmiesKilled.NumArmies;
				checkwin(order.PlayerID,addNewOrder,game);
			end
			if(toowner ~= WL.PlayerID.Neutral and game.ServerGame.Game.Players[toowner].IsAI == false)then
				if(result.IsSuccessful)then
					playerGameData[toowner].Lostterritories = playerGameData[toowner].Lostterritories+1;
					playerGameData[toowner].Ownedterritories = playerGameData[toowner].Ownedterritories-1;
				end
				playerGameData[toowner].Killedarmies = playerGameData[toowner].Killedarmies+result.AttackingArmiesKilled.NumArmies;
				playerGameData[toowner].Lostarmies = playerGameData[toowner].Lostarmies+result.DefendingArmiesKilled.NumArmies;
				checkwin(toowner,addNewOrder,game);
			end
		end
	end
end
function Server_AdvanceTurn_End (game,addNewOrder)
	Mod.PlayerGameData = playerGameData;
end
function checkwin(pid,addNewOrder,game)
	local completed = 0;
	local required = Mod.Settings.Conditionsrequiredforwin;
	if(Mod.Settings.Capturedterritories ~= 0)then
		if(playerGameData[pid].Capturedterritories >= Mod.Settings.Capturedterritories)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Lostterritories ~= 0)then
		if(playerGameData[pid].Lostterritories >= Mod.Settings.Lostterritories)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Ownedterritories ~= 0)then
		if(playerGameData[pid].Ownedterritories >= Mod.Settings.Ownedterritories)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Capturedbonuses ~= 0)then
		if(playerGameData[pid].Capturedbonuses >= Mod.Settings.Capturedbonuses)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Lostbonuses ~= 0)then
		if(playerGameData[pid].Lostbonuses >= Mod.Settings.Lostbonuses)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Ownedbonuses ~= 0)then
		if(playerGameData[pid].Ownedbonuses >= Mod.Settings.Ownedbonuses)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Killedarmies ~= 0)then
		if(playerGameData[pid].Killedarmies >= Mod.Settings.Killedarmies)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Lostarmies ~= 0)then
		if(playerGameData[pid].Lostarmies >= Mod.Settings.Lostarmies)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Ownedarmies ~= 0)then
		if(playerGameData[pid].Ownedarmies >= Mod.Settings.Ownedarmies)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Eleminateais ~= 0)then
		if(playerGameData[pid].Eleminateais >= Mod.Settings.Eleminateais)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Eleminateplayers ~= 0)then
		if(playerGameData[pid].Eleminateplayers >= Mod.Settings.Eleminateplayers)then
			completed = completed + 1;
		end
	end
	if(Mod.Settings.Eleminateaisandplayers ~= 0)then
		if(playerGameData[pid].Eleminateaisandplayers >= Mod.Settings.Eleminateaisandplayers)then
			completed = completed + 1;
		end
	end
	if(completed >= required)then
		local num = 0;
		local effect = {}
		for _,terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
			effect[num] = WL.TerritoryModification.Create(terr.ID);
			effect[num].SetOwnerTo(pid);
		end
		addNewOrder(WL.GameOrderEvent.Create(pid, "Win", nil, effect));
	end
end
