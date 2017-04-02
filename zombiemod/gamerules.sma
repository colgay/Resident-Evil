new bool:g_isGameStarted;
new bool:g_allowRespawn;
new g_countDown;

new bool:g_canRespawn[33];

GameRules::Precache()
{
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "OnInstallGameRules_Post", OrpheuHookPost);
}

GameRules::Init()
{
	OrpheuRegisterHookFromObject(g_pGameRules, "Think", "CGameRules", "GameRules@Think_Post", OrpheuHookPost);
	OrpheuRegisterHookFromObject(g_pGameRules, "FPlayerCanRespawn", "CGameRules", "OnPlayerCanRespawn");
	OrpheuRegisterHookFromObject(g_pGameRules, "CheckWinConditions", "CGameRules", "OnCheckWinConditions");
}

public OnInstallGameRules_Post()
{
	g_pGameRules = OrpheuGetReturn();
}

public GameRules::EntSpawn(ent)
{
	static const objectiveClasses[][] = 
	{
		"func_bomb_target",
		"info_bomb_target",
		"info_vip_start",
		"func_vip_safetyzone",
		"func_escapezone",
		"hostage_entity",
		"monster_scientist",
		"func_hostage_rescue",
		"info_hostage_rescue",
		"func_buyzone"
	};
	
	if (pev_valid(ent))
	{
		new classname[32];
		pev(ent, pev_classname, classname, charsmax(classname));
		
		for (new i = 0; i < sizeof objectiveClasses; i++)
		{
			if (equal(classname, objectiveClasses[i]))
			{
				remove_entity(ent);
				HOOK_RETURN(FMRES_SUPERCEDE);
			}
		}
	}
	
	HOOK_RETURN(FMRES_IGNORED);
}

GameRules::NewRound()
{
	g_isGameStarted = false;
	g_allowRespawn = false;
	g_countDown = 0;
	
	remove_task(TASK_ROUNDSTART);
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_connected(i))
		{
			setZombie(i, false);
		}
	}
}

GameRules::RoundStart()
{
	set_task(1.0, "TaskCountDown", TASK_ROUNDSTART, _, _, "b");
}

public GameRules::Think_Post()
{
	if (!getGameRules2("m_bFreezePeriod") && !getGameRules("m_iRoundWinStatus") && timeRemaining() < 1)
	{
		if (!getGameRules("m_bFirstConnected"))
		{
			terminateRound2(5.0, WinStatus_Draw, Event_Round_Draw, "#Round_Draw", "rounddraw");
		}
		else if (countHumans())
		{
			terminateRound2(5.0, WinStatus_CT, Event_CTs_Win, "#Target_Saved", "ctwin", true);
		}
		
		setGameRulesF("m_fRoundCount", getGameRulesF("m_fRoundCount") + 60.0);
	}
}

public OrpheuHookReturn:OnCheckWinConditions()
{
	if (getGameRules("m_bFirstConnected") && getGameRules("m_iRoundWinStatus"))
		return OrpheuIgnored;
	
	countTeamPlayers();
	
	new numTerrorist = getGameRules("m_iNumSpawnableTerrorist");
	new numCT = getGameRules("m_iNumSpawnableCT");
	
	// not enough players
	if (numTerrorist + numCT < 2)
	{
		setGameRules("m_bFirstConnected", false);
	}
	
	if (!getGameRules("m_bFirstConnected") && numTerrorist + numCT >= 2)
	{
		setGameRules2("m_bFreezePeriod", false);
		setGameRules("m_bCompleteReset", true);
		
		terminateRound2(3.0, WinStatus_Draw, Event_Game_Commencing, "#Game_Commencing");
		setGameRules("m_bFirstConnected", true);
		
		return OrpheuSupercede;
	}

	if (getGameRules("m_iRoundWinStatus"))
	{
		return OrpheuSupercede;
	}
	
	if (g_isGameStarted)
	{
		if (!countHumans())
		{
			terminateRound2(5.0, WinStatus_Terrorist, Event_Terrorists_Win, "#Terrorists_Win", "terwin", true);
		}
		else if ((!g_allowRespawn && !countZombies()) || (!countZombies() && !countRespawnables()))
		{
			terminateRound2(5.0, WinStatus_CT, Event_CTs_Win, "#CTs_Win", "ctwin", true);
		}
	}
	else
	{
		if (!countHumans())
		{
			terminateRound2(5.0, WinStatus_Draw, Event_Round_Draw, "#Round_Draw", "rounddraw");
		}
	}
	
	return OrpheuSupercede;
}

public OrpheuHookReturn:OnPlayerCanRespawn(this, id)
{
	if (getPlayerData(id, "m_iNumSpawns") > 0)
		return OrpheuIgnored;
	
	if (!g_isGameStarted && (TEAM_TERRORIST <= getPlayerData(id, "m_iTeam") <= TEAM_CT) && !isJoiningTeam(id))
		OrpheuSetReturn(true);
	else
		OrpheuSetReturn(false);
	
	return OrpheuOverride;
}

GameRules::PlayerSpawn(id)
{
	if (1 <= getPlayerData(id, "m_iTeam") <= 2)
	{
		if (isZombie(id))
			setPlayerData(id, "m_iTeam", TEAM_TERRORIST);
		else
			setPlayerData(id, "m_iTeam", TEAM_CT);
	}
}

GameRules::PlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		if (isZombie(id))
			infectPlayer(id);
		else
			humanizePlayer(id);
		
		g_canRespawn[id] = false;
	}
}

GameRules::PlayerKilled(id)
{
	if (canPlayerRespawn(id))
	{
		g_canRespawn[id] = true;
		
		remove_task(id + TASK_RESPAWN);
		set_task(3.0, "TaskRespawnPlayer", id + TASK_RESPAWN);
	}
	else
		g_canRespawn[id] = false;
}

GameRules::Infect_Post(id)
{
	setPlayerTeam(id, TEAM_TERRORIST);
	checkWinConditions();
}

GameRules::Humanize_Post(id)
{
	setPlayerTeam(id, TEAM_CT);
	checkWinConditions();
}

GameRules::Disconnect(id)
{
	remove_task(id + TASK_RESPAWN);
	g_canRespawn[id] = false;
}

public TaskRespawnPlayer(taskid)
{
	new id = taskid - TASK_RESPAWN;
	
	if (canPlayerRespawn(id))
	{
		setZombie(id, true);
		ExecuteHam(Ham_CS_RoundRespawn, id);
	}
	else
		g_canRespawn[id] = false;
}

public TaskCountDown()
{
	g_countDown++;
	
	new remaining = 20 - g_countDown;
	if (remaining > 0)
	{
		if (remaining <= 10)
		{
			new word[16];
			num_to_word(remaining, word, charsmax(word));
			
			set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(0, "The game will begin in %d second%s...", remaining, remaining > 1 ? "s" : "");
			
			client_cmd(0, "spk %s", word);
		}
	}
	else
	{
		remove_task(TASK_ROUNDSTART);
		MakeGameStart();
	}
}

public MakeGameStart()
{
	new players[32], numPlayers;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if ((1 <= getPlayerData(i, "m_iTeam") <= 2) && !isJoiningTeam(i))
			players[numPlayers++] = i;
	}
	
	if (numPlayers < 2)
	{
		set_task(2.0, "TaskCountPlayers", TASK_ROUNDSTART, .flags="b");
		return;
	}
	
	new player;
	for (new i = 0; i < numPlayers; i++)
	{
		player = players[i];
		
		if (!is_user_alive(player))
			respawnPlayer(player);
		
		if (isZombie(player))
			humanizePlayer(player);
	}
	
	new players2[32], numPlayers2;
	players2 = players;
	numPlayers2 = numPlayers;

	// Make zombies
	new numZombies = 0;
	new maxZombies = floatround(numPlayers * 0.25);
	
	while (numZombies < maxZombies && numPlayers2 >= 0)
	{
		player = getRandomPlayer(players2, numPlayers2, true);
		
		infectPlayer(player);
		set_pev(player, pev_health, pev(player, pev_health) * 2.0);
		
		numZombies++;
	}
	
	set_dhudmessage(200, 50, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
	show_dhudmessage(0, "The first batch of humans have been infected...");
	
	g_isGameStarted = true;
	g_allowRespawn = true;

	OnGameStart();
}

public TaskCountPlayers()
{
	new numPlayers = 0;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if ((TEAM_TERRORIST <= getPlayerData(i, "m_iTeam") <= TEAM_CT) && !isJoiningTeam(i))
			numPlayers++;
	}
	
	if (numPlayers >= 2)
	{
		remove_task(TASK_ROUNDSTART);
	}
	else
	{
		client_print(0, print_center, "Looking for %d more player%s...", 2 - numPlayers, numPlayers > 1 ? "s" : "");
	}
}

stock bool:canPlayerRespawn(id)
{
	if (!g_allowRespawn || !g_isGameStarted)
		return false;
	
	if (getGameRules("m_iRoundWinStatus"))
		return false;
	
	if (!(1 <= getPlayerData(id, "m_iTeam") <= 2) || isJoiningTeam(id))
		return false;
	
	if (is_user_alive(id))
		return false;
	
	return true;
}

stock bool:isRespawnable(id)
{
	return g_canRespawn[id];
}

stock countTeamPlayers()
{
	new numCT = 0;
	new numTerrorist = 0;
	new numSpawnableCT = 0;
	new numSpawnableTerrorist = 0;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		switch (getPlayerData(i, "m_iTeam"))
		{
			case TEAM_TERRORIST:
			{
				if (!isJoiningTeam(i))
					numSpawnableTerrorist++;
				
				numTerrorist++;
			}
			case TEAM_CT:
			{
				if (!isJoiningTeam(i))
					numSpawnableCT++;
				
				numCT++
			}
		}
	}

	setGameRules("m_iNumCT", numCT);
	setGameRules("m_iNumTerrorist", numTerrorist);
	setGameRules("m_iNumSpawnableCT", numSpawnableCT);
	setGameRules("m_iNumSpawnableTerrorist", numSpawnableTerrorist);
}

stock terminateRound(Float:delay, status)
{
	setGameRules("m_iRoundWinStatus", status);
	setGameRules("m_bRoundTerminating", true);
	setGameRulesF("m_fTeamCount", get_gametime() + delay);
}

stock terminateRound2(Float:delay, status, event, const message[], const audio[]="", bool:score=true)
{
	if (audio[0])
	{
		new code[32] = "%!MRAD_";
		add(code, charsmax(code), audio);
		sendAudioMsg(0, 0, code, 100);
	}
	
	if (score && status != WinStatus_Draw)
	{
		if (status == WinStatus_Terrorist)
			setGameRules("m_iNumTerroristWins", getGameRules("m_iNumTerroristWins") + 1);
		else if (status == WinStatus_CT)
			setGameRules("m_iNumCTWins", getGameRules("m_iNumCTWins") + 1);
		
		updateTeamScores();
	}
	
	endRoundMessage(message, event);
	terminateRound(delay, status);
}

stock checkWinConditions()
{
	static OrpheuFunction:func;
	func || (func = OrpheuGetFunction("CheckWinConditions", "CHalfLifeMultiplay"));
	
	OrpheuCallSuper(func, g_pGameRules);
}

stock endRoundMessage(const message[], event)
{
	static OrpheuFunction:func;
	func || (func = OrpheuGetFunction("EndRoundMessage"));
	
	OrpheuCallSuper(func, message, event);
}

stock updateTeamScores()
{
	static msgTeamScore;
	msgTeamScore || (msgTeamScore = get_user_msgid("TeamScore"));
	
	emessage_begin(MSG_BROADCAST, msgTeamScore);
	ewrite_string("CT");
	ewrite_short(getGameRules("m_iNumCTWins"));
	emessage_end();
	
	emessage_begin(MSG_BROADCAST, msgTeamScore);
	ewrite_string("TERRORIST");
	ewrite_short(getGameRules("m_iNumTerroristWins"));
	emessage_end();
}

stock sendAudioMsg(id, sender, const audio[], pitch)
{
	static msgSendAudio;
	msgSendAudio || (msgSendAudio = get_user_msgid("SendAudio"));
	
	emessage_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgSendAudio, _, id);
	ewrite_byte(sender);
	ewrite_string(audio);
	ewrite_short(pitch);
	emessage_end();
}

stock Float:timeRemaining()
{
	return float(getGameRules("m_iRoundTimeSecs")) - get_gametime() + getGameRulesF("m_fRoundCount");
}