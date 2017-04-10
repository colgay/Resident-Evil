new const SOUND_EVENT[] = "resident_evil/event2.wav";
new const SOUND_TITLE[] = "resident_evil/title.wav";
new const SOUND_STARTUP[] = "resident_evil/startup.wav";

new const MUSIC_GMONSTER[] = "sound/resident_evil/music/gmonster.mp3";
new const MUSIC_G2[] = "sound/resident_evil/music/g2.mp3";
new const MUSIC_G3[] = "sound/resident_evil/music/g3.mp3";

new const MUSIC_NEMESIS[] = "sound/resident_evil/music/nemesis.mp3";
new const MUSIC_N2[] = "sound/resident_evil/music/n2.mp3";

new const MUSIC_NG[] = "sound/resident_evil/music/ng.mp3";

new bool:g_isGameStarted;
new bool:g_allowRespawn;
new g_countDown;

new bool:g_canRespawn[33];

new g_isBossSpawned;
new g_isLeaderSpawned;
new g_gameMode;
new g_winStatus;

GameRules::Precache()
{
	precache_sound(SOUND_EVENT);
	precache_sound(SOUND_TITLE);
	precache_sound(SOUND_STARTUP);
	
	precache_generic(MUSIC_GMONSTER);
	precache_generic(MUSIC_G2);
	precache_generic(MUSIC_G3);
	
	precache_generic(MUSIC_NEMESIS);
	precache_generic(MUSIC_N2);
	
	precache_generic(MUSIC_NG);
	
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "OnInstallGameRules_Post", OrpheuHookPost);
}

GameRules::Init()
{
	register_clcmd("gamemode", "CmdGameMode");
	
	register_message(get_user_msgid("SendAudio"), "OnMsgSendAudio");
	register_message(get_user_msgid("TextMsg"), "OnMsgTextMsg");

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
	g_isBossSpawned = false;
	g_isLeaderSpawned = false;

	setMapLight("");
	stopMusic(0);
	stopSound(0);
	
	remove_task(TASK_ROUNDSTART);
	remove_task(TASK_MUSIC);
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_connected(i))
		{
			setZombie(i, false);
			setLeader(i, false);
		}
	}
}

GameRules::RoundStart()
{
	playSound(0, SOUND_STARTUP);
	set_task(1.0, "TaskCountDown", TASK_ROUNDSTART, _, _, "b");
}

GameRules::RoundEnd()
{
	switch (g_gameMode)
	{
		case GAMEMODE_NORMAL_G:
		{
			if (g_winStatus == WinStatus_CT) // Survivors win
			{
				// Boss was spawned
				if (g_isBossSpawned)
				{
					if (countGmonsters()) // G still alive
						g_gameMode = GAMEMODE_GMONSTER; // Single G next round
					else // G is dead
						g_gameMode = GAMEMODE_NORMAL_N; // Normal N next round
				}
				else
					g_gameMode = GAMEMODE_NORMAL_G; // Still...
			}
			else if (g_winStatus == WinStatus_Terrorist) // Zombies win
			{
				g_gameMode = GAMEMODE_NORMAL_G; // Still...
			}
		}
		case GAMEMODE_GMONSTER:
		{
			if (g_winStatus == WinStatus_CT) // Survivors win
			{
				if (countGmonsters()) // G still alive
					g_gameMode = GAMEMODE_NORMAL_G; // Normal G next round
				else // G is dead
					g_gameMode = GAMEMODE_NORMAL_N; // Normal N next round
			}
			else if (g_winStatus == WinStatus_Terrorist) // Zombies win
			{
				g_gameMode = GAMEMODE_NORMAL_G; // Still...
			}
		}
		case GAMEMODE_NORMAL_N:
		{
			if (g_winStatus == WinStatus_CT) // Survivors win
			{
				// Boss was spawned
				if (g_isBossSpawned)
				{
					if (countNemesis()) // N still alive
						g_gameMode = GAMEMODE_NEMESIS; // Single N next round
					else // N is dead
						g_gameMode = GAMEMODE_NG; // NG next round
				}
				else
					g_gameMode = GAMEMODE_NORMAL_N; // Still...
			}
			else if (g_winStatus == WinStatus_Terrorist) // Zombies win
			{
				g_gameMode = GAMEMODE_NORMAL_G; // Rollback
			}
		}
		case GAMEMODE_NEMESIS:
		{
			if (g_winStatus == WinStatus_CT) // Survivors win
			{
				if (countNemesis()) // N still alive
					g_gameMode = GAMEMODE_NORMAL_N; // Normal N next round
				else // N is dead
					g_gameMode = GAMEMODE_NG; // NG next round
			}
			else if (g_winStatus == WinStatus_Terrorist) // Zombies win
			{
				g_gameMode = GAMEMODE_NORMAL_G; // Rollback
			}
		}
		case GAMEMODE_NG:
		{
			if (g_winStatus == WinStatus_CT)
			{
				new g = countGmonsters();
				new n = countNemesis();
				
				// G and N are alive
				if (g && n)
					g_gameMode = GAMEMODE_NG; // Still...
				else if (n) // Only N is alive
					g_gameMode = GAMEMODE_NEMESIS; // Single N next round
				else if (g) // Only G is alive
					g_gameMode = GAMEMODE_GMONSTER; // Single G next round
				else // Both are dead
					g_gameMode = GAMEMODE_NG; // Still...
			}
			else if (g_winStatus == WinStatus_Terrorist)
			{
				g_gameMode = GAMEMODE_NORMAL_N; // Rollback
			}
		}
	}
	
	new point;
	
	if (g_winStatus == WinStatus_CT)
	{
		if (g_gameMode == GAMEMODE_NG)
		{
			// A boss was died
			if (!countGmonsters() || !countNemesis())
			{
				point = 15;
			}
			else
			{
				point = 12;
			}
		}
		else
		{
			if (g_isBossSpawned) // Boss was spawned
			{
				// Boss was died
				if (!countGmonsters() && !countNemesis())
				{
					point = 10;
				}
				else
				{
					point = 8;
				}
			}
			else
			{
				point = 6;
			}
		}
		
		for (new i = 1; i <= g_maxClients; i++)
		{
			if (is_user_alive(i) && !isZombie(i))
			{
				givePlayerReward(i, point);
			}
		}
		
		client_print_color(0, print_team_default, "* 所有生還者獲得 %d SP", point);
	}
	else if (g_winStatus == WinStatus_Terrorist)
	{
		if (g_isLeaderSpawned) // Leader was spawned
		{
			if (!countLeaders()) // Leader was died
			{
				point = 8;
			}
			else
			{
				point = 6;
			}
		}
		else
		{
			point = 4;
		}
		
		for (new i = 1; i <= g_maxClients; i++)
		{
			if (is_user_alive(i) && isZombie(i))
			{
				givePlayerReward(i, point);
			}
		}
		
		client_print(0, print_chat, "* 所有喪屍獲得 %d SP", point);
	}
	
	stopMusic(0);
}

public GameRules::Think_Post()
{
	if (!getGameRules2("m_bFreezePeriod") && !getGameRules("m_iRoundWinStatus") && timeRemaining() < 1)
	{
		if (!getGameRules("m_bFirstConnected"))
		{
			terminateRound2(5.0, WinStatus_Draw, Event_Round_Draw, "#Round_Draw", "rounddraw");
		}
		else
		{
			if (g_isBossSpawned && g_isLeaderSpawned && !countLeaders())
				terminateRound2(5.0, WinStatus_Terrorist, Event_Terrorists_Win, "#Terrorists_Win", "terwin", true);
			else if (countHumans())
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
	if (numTerrorist + numCT < 4)
	{
		setGameRules("m_bFirstConnected", false);
	}
	
	if (!getGameRules("m_bFirstConnected") && numTerrorist + numCT >= 4)
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

public OnMsgSendAudio(msgId, dest, id)
{
	new audio[32];
	get_msg_arg_string(2, audio, charsmax(audio));
	
	if (equal(audio, "%!MRAD_terwin"))
	{
		g_winStatus = WinStatus_Terrorist;
		//return PLUGIN_HANDLED;
	}
	else if (equal(audio, "%!MRAD_ctwin"))
	{
		g_winStatus = WinStatus_CT;
		//return PLUGIN_HANDLED;
	}
	else if (equal(audio, "%!MRAD_rounddraw"))
	{
		g_winStatus = WinStatus_Draw;
		//return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public OnMsgTextMsg(msgId, dest, id)
{
	new message[32];
	get_msg_arg_string(2, message, charsmax(message));
	
	if (equal(message, "#Terrorists_Win"))
	{
		set_dhudmessage(255, 0, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
		show_dhudmessage(0, "Zombies Win!");
		
		return PLUGIN_HANDLED;
	}
	else if (equal(message, "#CTs_Win"))
	{
		set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
		show_dhudmessage(0, "Survivors Win!");
		
		return PLUGIN_HANDLED;
	}
	else if (equal(message, "#Target_Saved"))
	{
		set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
		show_dhudmessage(0, "The humans were survived...");
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CmdGameMode(id)
{
	new arg[10];
	read_argv(1, arg, charsmax(arg));
	
	g_gameMode = str_to_num(arg);
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
	if (canPlayerRespawn(id, false))
	{
		g_canRespawn[id] = true;
		
		remove_task(id + TASK_RESPAWN);
		set_task(3.0, "TaskRespawnPlayer", id + TASK_RESPAWN);
	}
	else
		g_canRespawn[id] = false;
	
	checkHumanDeath(id);
	checkZombieDeath(id);
}

GameRules::Infect_Post(id)
{
	setPlayerTeam(id, TEAM_TERRORIST);
	checkWinConditions();

	checkHumanDeath(id);
	
	if (g_gameMode == GAMEMODE_NEMESIS || g_gameMode == GAMEMODE_NORMAL_N)
	{
		if (getNemesis(id) == NEMESIS_2ND)
			playMusicTask(5.0, MUSIC_N2);
	}
	else if (g_gameMode == GAMEMODE_GMONSTER || g_gameMode == GAMEMODE_NORMAL_G)
	{
		if (getGmonster(id) == GMONSTER_2ND)
			playMusicTask(5.0, MUSIC_G2);
		else if (getGmonster(id) == GMONSTER_3RD)
			playMusicTask(5.0, MUSIC_G3);
	}
}

GameRules::Humanize_Post(id)
{
	setPlayerTeam(id, TEAM_CT);
	checkWinConditions();
	
	checkZombieDeath(id);
}

GameRules::Disconnect(id)
{
	remove_task(id + TASK_RESPAWN);
	g_canRespawn[id] = false;
	
	checkHumanDeath(id);
	checkZombieDeath(id);
}

public TaskRespawnPlayer(taskid)
{
	new id = taskid - TASK_RESPAWN;
	
	if (canPlayerRespawn(id))
	{
		respawnPlayerAs(id);
		respawnPlayer(id);
	}
	else
	{
		g_canRespawn[id] = false;
	}
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

	OnGameStart();
	
	new player;
	for (new i = 0; i < numPlayers; i++)
	{
		player = players[i];
		
		if (isZombie(player))
			setZombie(player, false);

		if (!is_user_alive(player))
			respawnPlayer(player);
		
		if (isZombie(player))
			humanizePlayer(player);
	}
	
	new players2[32], numPlayers2;
	players2 = players;
	numPlayers2 = numPlayers;
	
	if (numPlayers >= 6)
	{
		if (g_gameMode == GAMEMODE_NG)
		{
			new player1 = getRandomPlayer(players2, numPlayers2, true);
			setLeader(player1, LEADER_MALE);
			humanizePlayer(player1);
			
			new player2 = getRandomPlayer(players2, numPlayers2, true);
			setLeader(player2, LEADER_FEMALE);
			humanizePlayer(player2);
			
			g_isLeaderSpawned = true;
			
			set_hudmessage(50, 100, 200, 0.025, 0.3, 0, 0.0, 3.0, 1.0, 1.0, 2);
			show_hudmessage(0, "%n is Leader^n%n is Leader", player1, player2);
		}
		else
		{
			new player = getRandomPlayer(players2, numPlayers2, true);
			setLeader(player, random_num(LEADER_MALE, LEADER_FEMALE));
			humanizePlayer(player);
			
			g_isLeaderSpawned = true;
			
			if (getLeader(player) == LEADER_MALE)
				set_hudmessage(50, 100, 200, 0.025, 0.3, 0, 0.0, 3.0, 1.0, 1.0, 2);
			else
				set_hudmessage(200, 50, 50, 0.025, 0.3, 0, 0.0, 3.0, 1.0, 1.0, 2);
				
			show_hudmessage(0, "%n is Leader", player);
		}
	}

	switch (g_gameMode)
	{
		case GAMEMODE_NORMAL_G, GAMEMODE_NORMAL_N:
		{
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
			
			g_isGameStarted = true;
			g_allowRespawn = true;
			
			setMapLight("b");
			
			set_dhudmessage(200, 50, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
			show_dhudmessage(0, "The first batch of humans have been infected...");

			playSound(0, SOUND_TITLE);
		}
		case GAMEMODE_GMONSTER:
		{
			new player = getRandomPlayer(players2, numPlayers2, true);
			setGmonster(player, GMONSTER_1ST);
			infectPlayer(player);
			
			g_isBossSpawned = true;
			
			setMapLight("b");

			g_isGameStarted = true;
			g_allowRespawn = true;
			g_isBossSpawned = true;

			set_dhudmessage(200, 0, 200, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
			show_dhudmessage(0, "G-Virus Monster Detected");
			
			playSound(0, SOUND_EVENT);
			playMusicTask(8.0, MUSIC_GMONSTER);
		}
		case GAMEMODE_NEMESIS:
		{
			new player = getRandomPlayer(players2, numPlayers2, true);
			setNemesis(player, NEMESIS_1ST);
			infectPlayer(player);
			
			setMapLight("b");

			g_isGameStarted = true;
			g_allowRespawn = true;
			g_isBossSpawned = true;

			set_dhudmessage(255, 0, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
			show_dhudmessage(0, "Nemesis Detected");
			
			playSound(0, SOUND_EVENT);
			playMusicTask(8.0, MUSIC_NEMESIS);
		}
		case GAMEMODE_NG:
		{
			new player = getRandomPlayer(players2, numPlayers2, true);
			setGmonster(player, GMONSTER_1ST);
			setZombie(player, true);
			
			player = getRandomPlayer(players2, numPlayers2, true);
			setNemesis(player, NEMESIS_1ST);
			setZombie(player, true);
			
			for (new i = 0; i < numPlayers; i++)
			{
				player = players[i];
				if (isZombie(player))
					infectPlayer(player);
			}
			
			g_isGameStarted = true;
			g_allowRespawn = false;
			g_isBossSpawned = true;

			set_dhudmessage(50, 100, 200, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
			show_dhudmessage(0, "Nemesis & G-Virus Monster Detected");
			
			setMapLight("a");
			
			playSound(0, SOUND_EVENT);
			playMusicTask(8.0, MUSIC_NG);
		}
	}
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
	
	if (numPlayers >= 4)
	{
		remove_task(TASK_ROUNDSTART);
	}
	else
	{
		client_print(0, print_center, "Looking for %d more player%s...", 4 - numPlayers, numPlayers > 1 ? "s" : "");
	}
}

public TaskPlayMusic(param[])
{
	new music[128];
	copy(music, charsmax(music), param);
	
	playMusic(0, music, true);
}

stock checkHumanDeath(id)
{
	if (getLeader(id))
	{
		client_cmd(id, "spk \"the leak(e70) order(s30) is die\"");
	}
}

stock checkZombieDeath(id)
{
	if (getNemesis(id))
	{
		set_dhudmessage(0, 75, 200, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
		show_dhudmessage(0, "Nemesis has been destoryed...");

		if (g_gameMode == GAMEMODE_NORMAL_N || g_gameMode == GAMEMODE_NEMESIS)
		{
			g_allowRespawn = false;
			stopMusicTask();
		}
		
		client_cmd(0, "spk \"the biological weapon has been destroyed\"");
	}
	else if (getGmonster(id))
	{
		set_dhudmessage(0, 75, 200, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
		show_dhudmessage(0, "G-Virus Monster has been killed...");

		if (g_gameMode == GAMEMODE_NORMAL_G || g_gameMode == GAMEMODE_GMONSTER)
		{
			g_allowRespawn = false;
			stopMusicTask();
		}
		
		client_cmd(0, "spk \"the mode(e45) one(s20e70) mister(s25) has been destroyed\"");
	}
}

stock respawnPlayerAs(id)
{
	enum _:RespawnAs
	{
		RespawnAsZombie = 0,
		RespawnAsNemesis,
		RespawnAsGmonster,
		RespawnAsCombiner,
		RespawnAsMorpheus,
	};

	new array[RespawnAs], size = 0;
	
	for (new i = 0; i < RespawnAs; i++)
	{
		array[size++] = i;
	}

	new rand, type;
	new Float:ratio;
	
	while (size)
	{
		rand = random(size);
		type = array[rand];
	
		array[rand] = array[--size];
		
		switch (type)
		{
			case RespawnAsZombie:
			{
				setZombie(id, true);
				break;
			}
			case RespawnAsNemesis:
			{
				if (g_isBossSpawned || g_gameMode != GAMEMODE_NORMAL_N)
					continue;
				
				// 60% of round time
				ratio = 0.6 * (1.0 - (timeRemaining() / float(getGameRules("m_iRoundTimeSecs"))));
				
				// 25% of humans and zombies ratio
				ratio += 0.25 * (countHumans() / float(countAlivePlayers()));
				
				// 15% of leader
				ratio += countLeaders() ? 0.15 : 0.05;
				
				// 20% overall
				ratio *= 0.2;
				
				if (random_float(0.0, 1.0) > ratio)
					continue;

				setZombie(id, true);
				setNemesis(id, NEMESIS_1ST);
				
				g_isBossSpawned = true;
				
				set_dhudmessage(255, 0, 0, -1.0, 0.2, 1, 0.0, 3.0, 1.0, 1.0);
				show_dhudmessage(0, "Nemesis Detected");
				
				playSound(0, SOUND_EVENT);
				playMusicTask(8.0, MUSIC_NEMESIS);
				stopMusic(0);

				break;
			}
			case RespawnAsGmonster:
			{
				if (g_isBossSpawned || g_gameMode != GAMEMODE_NORMAL_G)
					continue;
				
				// 55% of round time
				ratio = 0.55 * (1.0 - (timeRemaining() / float(getGameRules("m_iRoundTimeSecs"))));
				
				// 30% of humans and zombies ratio
				ratio += 0.3 * (countHumans() / float(countAlivePlayers()));
				
				// 15% of leader
				ratio += countLeaders() ? 0.15 : 0.06;
				
				// 23% overall
				ratio *= 0.23;
				
				if (random_float(0.0, 1.0) > ratio)
					continue;

				setZombie(id, true);
				setGmonster(id, GMONSTER_1ST);
				
				g_isBossSpawned = true;
				
				set_dhudmessage(200, 0, 200, -1.0, 0.2, 1, 0.0, 3.0, 1.0, 1.0);
				show_dhudmessage(0, "G-Virus Monster Detected");
				
				playSound(0, SOUND_EVENT);
				playMusicTask(8.0, MUSIC_GMONSTER);
				stopMusic(0);

				break;
			}
			case RespawnAsCombiner:
			{
				if (countCombiners())
					continue;
				
				// 25% of round time
				ratio = 0.25 * (1.0 - (timeRemaining() / float(getGameRules("m_iRoundTimeSecs"))));
				
				// 50% of humans and zombies ratio
				ratio += 0.5 * (countHumans() / float(countAlivePlayers()));
				
				// 25% of leader
				ratio += countLeaders() ? 0.25 : 0.05;
				
				// 25% overall
				ratio *= 0.25;
				
				if (random_float(0.0, 1.0) > ratio)
					continue;

				setZombie(id, true);
				setCombiner(id, true);
				
				set_dhudmessage(0, 150, 200, 0.025, 0.3, 1, 0.0, 3.0, 1.0, 1.0);
				show_dhudmessage(0, "Combiner Detected");
				
				playSound(0, SOUND_WARNING);
				break;
			}
			case RespawnAsMorpheus:
			{
				if (countMorpheus())
					continue;
				
				// 30% of round time
				ratio = 0.3 * (1.0 - (timeRemaining() / float(getGameRules("m_iRoundTimeSecs"))));
				
				// 45% of humans and zombies ratio
				ratio += 0.45 * (countHumans() / float(countAlivePlayers()));
				
				// 25% of leader
				ratio += countLeaders() ? 0.25 : 0.05;
				
				// 20% overall
				ratio *= 0.20;
				
				if (random_float(0.0, 1.0) > ratio)
					continue;

				setZombie(id, true);
				setMorpheus(id, true);
				
				set_dhudmessage(200, 0, 0, 0.025, 0.3, 1, 0.0, 3.0, 1.0, 1.0);
				show_dhudmessage(0, "Morpheus Detected");
				
				playSound(0, SOUND_WARNING);
				break;
			}
		}
	}
}

stock playMusicTask(Float:delay, const music[])
{
	new param[128];
	copy(param, charsmax(param), music);
	
	remove_task(TASK_MUSIC);
	set_task(delay, "TaskPlayMusic", TASK_MUSIC, param, sizeof param);
}

stock stopMusicTask()
{
	remove_task(TASK_MUSIC);
	stopMusic(0);
}

stock bool:canPlayerRespawn(id, bool:checkAlive=true)
{
	if (!g_allowRespawn || !g_isGameStarted)
		return false;
	
	if (getGameRules("m_iRoundWinStatus"))
		return false;
	
	if (!(1 <= getPlayerData(id, "m_iTeam") <= 2) || isJoiningTeam(id))
		return false;
	
	if (checkAlive && is_user_alive(id))
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