stock getRandomPlayer(players[32], &numPlayers, bool:remove=true)
{
	if (numPlayers < 0)
		return 0;
	
	new rand = random(numPlayers);
	new player = players[rand];
	
	if (remove && numPlayers > 0)
		players[rand] = players[--numPlayers];
	
	return player;
}

stock respawnPlayer(id)
{
	ExecuteHam(Ham_CS_RoundRespawn, id);
}

stock resetPlayerMaxSpeed(id)
{
	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);
}

stock sendDamage(id, dmgSave, dmgTake, damageBits, Float:origin[3])
{
	static msgDamage;
	msgDamage || (msgDamage = get_user_msgid("Damage"));
	
	message_begin(MSG_ONE_UNRELIABLE, msgDamage, _, id);
	write_byte(dmgSave); // damage save
	write_byte(dmgTake); // damage take
	write_long(damageBits); // damage type
	write_coord_f(origin[0]); // x
	write_coord_f(origin[1]); // y
	write_coord_f(origin[2]); // z
	message_end();
}

stock Float:getEntSpeed(ent)
{
	new Float:vel[3];
	entity_get_vector(ent, EV_VEC_velocity, vel);

	return vector_length(vel);
}

stock getWeaponBoxType(ent) 
{ 
	new weapon;
	for (new i = 1; i<= 5; i++)
	{
		weapon = get_ent_data_entity(ent, "CWeaponBox", "m_rgpPlayerItems", i);
		
		if (pev_valid(weapon))
			return cs_get_weapon_id(weapon);
	}

	return 0;
}

stock playSound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound);
}

stock precachePlayerModel(const model[])
{
	new buffer[128];
	formatex(buffer, charsmax(buffer), "models/player/%s/%s.mdl", model, model);
	precache_model(buffer);
	
	formatex(buffer, charsmax(buffer), "models/player/%s/%sT.mdl", model, model);
	if (file_exists(buffer))
		precache_model(buffer);
}

stock getWeaponAnim(id)
{
	return pev(id, pev_weaponanim);
}

stock sendScreenFade(id, Float:duration, Float:holdTime, flags, color[3], alpha, bool:external=false)
{
	static msgScreenFade;
	msgScreenFade || (msgScreenFade = get_user_msgid("ScreenFade"));
	
	if (external)
	{
		emessage_begin(MSG_ONE_UNRELIABLE, msgScreenFade, _, id);
		ewrite_short(fixedUnsigned16(duration, 1<<12));
		ewrite_short(fixedUnsigned16(holdTime, 1<<12));
		ewrite_short(flags);
		ewrite_byte(color[0]);
		ewrite_byte(color[1]);
		ewrite_byte(color[2]);
		ewrite_byte(alpha);
		emessage_end();
	}
	else
	{
		message_begin(MSG_ONE_UNRELIABLE, msgScreenFade, _, id);
		write_short(fixedUnsigned16(duration, 1<<12));
		write_short(fixedUnsigned16(holdTime, 1<<12));
		write_short(flags);
		write_byte(color[0]);
		write_byte(color[1]);
		write_byte(color[2]);
		write_byte(alpha);
		message_end();
	}
}

stock fixedUnsigned16(Float:value, scale)
{
	new output = floatround(value * scale);
	return clamp(output, 0, 0xFFFF);
}

stock dropWeapons(id, slot=0)
{
	for (new i = 1; i <= 5; i++)
	{
		if (slot && slot != i)
			continue;
		
		new weapon = get_ent_data_entity(id, "CBasePlayer", "m_rgpPlayerItems", i);
		
		while (pev_valid(weapon))
		{
			if (ExecuteHamB(Ham_CS_Item_CanDrop, weapon))
			{
				static class[32];
				pev(weapon, pev_classname, class, charsmax(class));
				
				engclient_cmd(id, "drop", class);
			}
			
			// Find next weapon
			weapon = get_ent_data_entity(weapon, "CBasePlayerItem", "m_pNext");
		}
	}
}

stock bool:isJoiningTeam(id)
{
	return (getPlayerData(id, "m_iMenu") == 3);
}

stock setPlayerTeam(id, team, bool:scoreBoard=true, bool:checkTeam=true)
{
	if (checkTeam && getPlayerData(id, "m_iTeam") == team)
		return;
	
	setPlayerData(id, "m_iTeam", team);
	
	if (scoreBoard)
	{
		static msgTeamInfo;
		msgTeamInfo || (msgTeamInfo = get_user_msgid("TeamInfo"));
		
		emessage_begin(MSG_BROADCAST, msgTeamInfo);
		ewrite_byte(id);
		switch (team)
		{
			case 1: ewrite_string("TERRORIST");
			case 2: ewrite_string("CT");
			case 3: ewrite_string("SPECTATOR");
			default: ewrite_string("UNASSIGNED");
		}
		emessage_end();
	}
}

stock countRespawnables()
{
	new count = 0;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_connected(i) && isRespawnable(i))
			count++;
	}
	
	return count;
}

stock OrpheuStruct:get_ppmove()
{
	return OrpheuGetStructFromAddress(OrpheuStructPlayerMove, OrpheuMemoryGet("ppmove"));
}

stock countAlivePlayers()
{
	new count = 0;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_alive(i))
			count++;
	}
	
	return count;
}

stock updateScoreInfo(id, class=0)
{
	static msgScoreInfo;
	msgScoreInfo || (msgScoreInfo = get_user_msgid("ScoreInfo"));
	
	emessage_begin(MSG_BROADCAST, msgScoreInfo);
	ewrite_byte(id); // player
	ewrite_short(get_user_frags(id)); // frags
	ewrite_short(getPlayerData(id, "m_iDeaths")); // deaths
	ewrite_short(class); // class
	ewrite_short(getPlayerData(id, "m_iTeam")); // team
	emessage_end();
}

stock sendDeathMsg(killer, victim, headShot, const weapon[], bool:external=true)
{
	static msgDeathMsg;
	msgDeathMsg || (msgDeathMsg = get_user_msgid("DeathMsg"));
	
	if (external)
	{
		emessage_begin(MSG_BROADCAST, msgDeathMsg);
		ewrite_byte(killer); // killer
		ewrite_byte(victim); // victim
		ewrite_byte(headShot); // headshot
		ewrite_string(weapon); // weapon
		emessage_end();
	}
	else
	{
		message_begin(MSG_BROADCAST, msgDeathMsg);
		write_byte(killer); // killer
		write_byte(victim); // victim
		write_byte(headShot); // headshot
		write_string(weapon); // weapon
		message_end();
	}
}

stock setScoreAttrib(id, attrib)
{
	static msgScoreAttrib;
	msgScoreAttrib || (msgScoreAttrib = get_user_msgid("ScoreAttrib"));
	
	message_begin(MSG_BROADCAST, msgScoreAttrib);
	write_byte(id); // id
	write_byte(attrib); // attrib
	message_end();
}