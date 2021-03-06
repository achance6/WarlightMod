function Server_GameCustomMessage(game, playerID, payload, setReturnTable)
	playerGameData = Mod.PlayerGameData;
	local rg = {};
	if(payload.Message == "Accept Allianze" or payload.Message == "Deny Allianze")then
		if(playerGameData[playerID].AllyOffers[payload.OfferedBy] == nil)then
			--offer doesn't exist any longer
			rg.Message = "The Ally offer doesn't exist, maybe you already accepted or declined it. The next time you reload the game, it shouldn't be shown there.";
			setReturnTable(rg);
		else
			playerGameData[playerID].AllyOffers[payload.OfferedBy] = nil;
			if(payload.Message == "Accept Allianze")then
				playerGameData[payload.OfferedBy].AllyOffers[playerID] = nil;
				playerGameData[playerID].Allianzen[tablelength(playerGameData[playerID].Allianzen)+1] = payload.OfferedBy;
				playerGameData[payload.OfferedBy].Allianzen[tablelength(playerGameData[payload.OfferedBy].Allianzen)+1] = playerID;
				--accept ally message
				local message = {};
				message.OfferedBy = payload.OfferedBy;
				message.AcceptedBy = playerID;
				message.Turn = game.Game.NumberOfTurns;
				message.Type = 16;
				if(Mod.Settings.PublicAllies == true)then
					for _,pd in pairs(game.ServerGame.Game.Players)do
						if(pd.IsAI == false)then
							addmessagecustom(message,pd.ID);
						end
					end
				else
					addmessagecustom(message,playerID);
					addmessagecustom(message,payload.OfferedBy);
				end
				Mod.PlayerGameData = playerGameData;
				rg.Message = "You successfuly accepted the ally offer.";
				setReturnTable(rg);
			else
				--declined ally message
				local message = {};
				message.OfferedBy = payload.OfferedBy;
				message.DeclinedBy = playerID;
				message.Turn = game.Game.NumberOfTurns;
				message.Type = 17;
				addmessagecustom(message,playerID);
				addmessagecustom(message,payload.OfferedBy);
				Mod.PlayerGameData = playerGameData;
				rg.Message = "You successfuly declined the ally offer.";
				setReturnTable(rg);
			end
		end	
	end
	if(payload.Message == "Offer Allianze")then
		local target = tonumber(payload.TargetPlayerID);
		if(playerGameData[target].AllyOffers[playerID] == nil)then
			playerGameData[target].AllyOffers[playerID] = {};
			playerGameData[target].AllyOffers[playerID].OfferedBy = playerID;
			playerGameData[target].AllyOffers[playerID].OfferedInTurn = game.Game.NumberOfTurns;
			local message = {};
			message.OfferedBy = playerID;
			message.OfferedTo = target;
			message.Turn = game.Game.NumberOfTurns;
			message.Type = 15;
			addmessagecustom(message,playerID);
			addmessagecustom(message,target);
			Mod.PlayerGameData = playerGameData;
			rg.Message = "The Player recieved the ally offer";
			setReturnTable(rg);
		else
			rg.Message = "The Player has already a pending ally offer by you";
			setReturnTable(rg);
		end
	end
 	if(payload.Message == "Peace")then
		local player = payload.TargetPlayerID;
		local preis = payload.Preis;
		local dauer = payload.duration;
		if(dauer > 10)then
			rg.Message = "S:To prevent this game from stucking, I limited the max duration of peace to 10turns";
			setReturnTable(rg);
		end
		if(game.ServerGame.Game.Players[player].IsAIOrHumanTurnedIntoAI == false)then
			if(playerGameData[player].Peaceoffers[playerID] ~= nil)then
				rg.Message = "The Player has already a pending peace offer by you";
				setReturnTable(rg);
			else
				playerGameData[player].Peaceoffers[playerID] = {};
				playerGameData[player].Peaceoffers[playerID].Duration = dauer;
				playerGameData[player].Peaceoffers[playerID].Preis = preis;
				playerGameData[player].Peaceoffers[playerID].Offerby = playerID;
				Mod.PlayerGameData=playerGameData;
				rg.Message = "The Offer has been submitted";
				setReturnTable(rg);
			end
		else
			if(preis ~= 0)then
				rg.Message = "S:AIs don't accept offers that include money";
				setReturnTable(rg);
			else
				if(game.ServerGame.Game.Players[player].IsAI == false)then
					--since human ais can have peaceoffers, before the turn into ai, this removes the old offers
					playerGameData[playerID].Peaceoffers[player] = nil;
				end
				local message = {};
				message.Acceptor = player;
				message.Von = playerID;
				message.Duration = dauer;
				message.Turn = game.Game.NumberOfTurns;
				message.Type = 10;
				message.Preis = 0;--this line can be removed and replaced by clientcode to reduce costs
				addmessagecustom(message,playerID);
				message = {};
				message.Von = player;
				message.Acceptor = playerID;
				message.Duration = dauer;
				message.Turn = game.Game.NumberOfTurns;
				message.Type = 10;
				for _,pid in pairs(game.ServerGame.Game.Players)do
					if(pid.IsAI == false and pid.ID ~= player and pid.ID ~= playerID)then
						addmessagecustom(message,pid.ID);
					end
				end
				Mod.PlayerGameData=playerGameData;
				publicGameData = Mod.PublicGameData;
				local remainingwar = {};
				for _,with in pairs(publicGameData.War[player]) do
					if(with~=playerID)then
						remainingwar[tablelength(remainingwar)+1] = with;
					end
				end
				publicGameData.War[player] = remainingwar;
				remainingwar = {};
				for _,with in pairs(publicGameData.War[playerID]) do
					if(with~=player)then
						remainingwar[tablelength(remainingwar)+1] = with;
					end
				end
				publicGameData.War[playerID] = remainingwar;
				publicGameData.CantDeclare[player][playerID] = dauer;
				publicGameData.CantDeclare[playerID][player] = dauer;
				Mod.PublicGameData = publicGameData;
				rg.Message = 'The AI accepted your offer';
				setReturnTable(rg);
			end
		end
	end
	if(payload.Message == "Accept Peace" or payload.Message == "Decline Peace")then
		local player = tonumber(payload.TargetPlayerID);
		if(playerGameData[playerID].Peaceoffers[player] == nil)then
			rg.Message = "The Peace Offer doesn't exist, maybe you already accepted or declined it. The next time you reload the game, it shouldn't be shown there.";
			setReturnTable(rg);
		else
			if(payload.Message == "Accept Peace")then
				local preis = 0;
				--local preis = playerGameData[playerID].Peaceoffers[player].Preis;
				local dauer = playerGameData[playerID].Peaceoffers[player].Duration;
				--Pay(player,playerID,preis,playerGameData,game,true)
				local remainingwar = {};
				publicGameData = Mod.PublicGameData;
				for _,with in pairs(publicGameData.War[player]) do
					if(with~=playerID)then
						remainingwar[tablelength(remainingwar)+1] = with;
					end
				end
				publicGameData.War[player] = remainingwar;
				remainingwar = {};
				for _,with in pairs(publicGameData.War[playerID]) do
					if(with~=player)then
						remainingwar[tablelength(remainingwar)+1] = with;
					end
				end
				publicGameData.War[playerID] = remainingwar;
				publicGameData.CantDeclare[player][playerID] = dauer;
				publicGameData.CantDeclare[playerID][player] = dauer;
				Mod.PublicGameData = publicGameData;
				local message = {};
				message.Von = player;
				message.Acceptor = playerID;
				message.Duration = dauer;
				message.Turn = game.Game.NumberOfTurns;
				message.Type = 10;
				message.Preis = preis;
				addmessagecustom(message,playerID);
				addmessagecustom(message,player);
				message = {};
				message.Von = player;
				message.Acceptor = playerID;
				message.Duration = dauer;
				message.Turn = game.Game.NumberOfTurns;
				message.Type = 10;
				for _,pid in pairs(game.ServerGame.Game.Players)do
					if(pid.IsAI == false and pid.ID ~= player and pid.ID ~= playerID)then
						addmessagecustom(message,pid.ID);
					end
				end
				playerGameData[playerID].Peaceoffers[player] = nil
				playerGameData[player].Peaceoffers[playerID] = nil
				Mod.PlayerGameData=playerGameData;
				rg.Message = "The Peace Offer has been accepted.";
				setReturnTable(rg);
			else
				Mod.PlayerGameData=playerGameData;
				local message = {};
				message.Von = player;
				message.DeclinedBy = playerID;
				message.Duration = playerGameData[playerID].Peaceoffers[player].Duration;
				message.Turn = game.Game.NumberOfTurns;
				message.Type = 11;
				message.Preis = playerGameData[playerID].Peaceoffers[player].Preis;
				addmessagecustom(message,playerID);
				addmessagecustom(message,player);
				playerGameData[playerID].Peaceoffers[player] = nil
				Mod.PlayerGameData=playerGameData;
				rg.Message = "The Peace Offer has been declined.";
				setReturnTable(rg);
			end
		end
	end
	if(payload.Message == "Territory Sell")then
		local target = tonumber(payload.TargetPlayerID);--target == 0 = everyone
		local Preis = payload.Preis;
		if(Preis <0)then
			rg.Message = "Price invailid.";
			setReturnTable(rg);
			return;
		end
		local targetterr = tonumber(payload.TargetTerritoryID);
		if(target == 0)then
			--option everyone
			local addedoffers = 0;
			local alreadyoffered = 0;
			for _,pid in pairs(game.ServerGame.Game.Players)do
				if(pid.IsAI == false and pid.ID ~= playerID)then
					if(playerGameData[pid.ID].TerritorySellOffers[playerID] == nil)then
						playerGameData[pid.ID].TerritorySellOffers[playerID] = {};
					end
					if(playerGameData[pid.ID].TerritorySellOffers[playerID][targetterr] == nil)then
						playerGameData[pid.ID].TerritorySellOffers[playerID][targetterr] = {};
						playerGameData[pid.ID].TerritorySellOffers[playerID][targetterr].Preis = Preis;
						playerGameData[pid.ID].TerritorySellOffers[playerID][targetterr].Player = playerID;
						playerGameData[pid.ID].TerritorySellOffers[playerID][targetterr].terrID = targetterr;
						playerGameData[pid.ID].TerritorySellOffers[playerID][targetterr].OfferedInTurn = game.Game.NumberOfTurns;
						addedoffers = addedoffers + 1;
					else
						 alreadyoffered = alreadyoffered + 1;
					end
				end
			end
			if(addedoffers==0)then
				Mod.PlayerGameData = playerGameData;
				rg.Message ='Every player has already a pending territory sell offer for that territoy by you.';
				setReturnTable(rg);
			else
				if(alreadyoffered > 0)then
					rg.Message ='You successfully added ' .. tostring(addedoffers) .. ' Territory Sell Offers ' .. '\n' .. tostring(alreadyoffered) .. ' players had already a territory sell offer for that territory';
				else
					rg.Message ='You successfully added ' .. tostring(addedoffers) .. ' Territory Sell Offers';
				end
				Mod.PlayerGameData = playerGameData;
				setReturnTable(rg);
			end
		else
			if(playerGameData[target].TerritorySellOffers[playerID] == nil)then
				playerGameData[target].TerritorySellOffers[playerID] = {};
			end
			if(playerGameData[target].TerritorySellOffers[playerID][targetterr] ~= nil)then
				rg.Message ='The player has already a pending territory sell offer by you for that territory.';
				setReturnTable(rg);
			else
				playerGameData[target].TerritorySellOffers[playerID][targetterr] = {};
				playerGameData[target].TerritorySellOffers[playerID][targetterr].Preis = Preis;
				playerGameData[target].TerritorySellOffers[playerID][targetterr].Player = playerID;
				playerGameData[target].TerritorySellOffers[playerID][targetterr].terrID = targetterr;
				playerGameData[target].TerritorySellOffers[playerID][targetterr].OfferedInTurn = game.Game.NumberOfTurns;
				Mod.PlayerGameData = playerGameData;
				rg.Message ='The player recieved the offer.';
				setReturnTable(rg);
			end
		end
	end
	if(payload.Message == "Deny Territory Sell")then
		local von = tonumber(payload.TargetPlayerID);
		local terr = tonumber(payload.TargetTerritoryID);
		if(playerGameData[playerID].TerritorySellOffers[von] ~= nil)then
			playerGameData[playerID].TerritorySellOffers[von][terr] = nil;
		end
		if(tablelength(playerGameData[playerID].TerritorySellOffers[von]) == 0)then
			playerGameData[playerID].TerritorySellOffers[von] = nil;
		end
		local message = {};
		message.Von = von;
		message.TerrID = terr;
		message.Turn = game.Game.NumberOfTurns;
		message.Type = 8;
		addmessagecustom(message,playerID);
		message = {};
		message.Revoker = playerID;
		message.TerrID = terr;
		message.Turn = game.Game.NumberOfTurns;
		message.Type = 9;
		addmessagecustom(message,von);
		Mod.PlayerGameData = playerGameData;
		rg.Message = "You succesfully denied the territory sell offer";
		setReturnTable(rg);
	end
end
function tablelength(T)
	local count = 0;
	for _,elem in pairs(T)do
		count = count + 1;
	end
	return count;
end
function addmessagecustom(message,spieler)
	print("spieler " .. spieler);
	if(playerGameData[spieler] == nil)then	--fix for new games irrelevant
		playerGameData[spieler] = {};
		playerGameData[spieler].TerritorySellOffers = {};
		playerGameData[spieler].Peaceoffers = {};
		playerGameData[spieler].AllyOffers = {};
		playerGameData[spieler].Allianzen = {};
		playerGameData[spieler].Nachrichten = {};
		playerGameData[spieler].NeueNachrichten = {};
	end
	if(playerGameData[spieler].Nachrichten == nil)then
		playerGameData[spieler].Nachrichten = {};
	end
	if(playerGameData[spieler].NeueNachrichten == nil)then
		playerGameData[spieler].NeueNachrichten = {};
	end
	playerGameData[spieler].Nachrichten[tablelength(playerGameData[spieler].Nachrichten)+1] = message;
	playerGameData[spieler].NeueNachrichten[tablelength(playerGameData[spieler].NeueNachrichten)+1] = message;
end
function GetOffer(offertype,spieler1,spieler2,terr)
	if(offertype ~= nil)then
		if(offertype[spieler1] ~= nil)then
			if(offertype[spieler1][spieler2] ~= nil)then
				if(terr ~= nil)then
					if(offertype[spieler1][spieler2][terr] ~= nil)then
						return offertype[spieler1][spieler2][terr];
					end
				else
					return offertype[spieler1][spieler2];
				end
			end
		end
	end
	return nil;
end
