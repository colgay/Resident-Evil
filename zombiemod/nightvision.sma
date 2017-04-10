new Float:g_nextScreenFade[33];
new Float:g_screenFadeUntil[33];
new bool:g_nightVisionOn[33];
new bool:g_hasNightVision[33];

new g_light[32];
new g_defaultLight[32];
new g_playerLight[33][32];

NightVision::Precache()
{
	precache_sound("items/nvg_on.wav");
	precache_sound("items/nvg_off.wav");
}

NightVision::Init()
{
	register_clcmd("nightvision", "CmdNightVision");
	register_event("ScreenFade", "NightVision@ScreenFade", "ab", "7>0");
	register_forward(FM_LightStyle, "NightVision@LightStyle");
}

NightVision::NewRound()
{
	arrayset(g_hasNightVision, false, sizeof g_hasNightVision);
}

NightVision::PutInServer(id)
{
	set_task(0.1, "FixLightStyle", id + TASK_LIGHT);
}

NightVision::Disconnect(id)
{
	remove_task(id + TASK_LIGHT);
	
	g_hasNightVision[id] = false;
	g_nightVisionOn[id] = false;
	g_playerLight[id][0] = 0;
}

NightVision::Spawn_Post(id)
{
	nightVisionToggle(id, false, true, false);
}

NightVision::Killed_Post(id)
{
	nightVisionToggle(id, false, true, false);
	g_hasNightVision[id] = false;
}

NightVision::Humanize_Post(id)
{
	nightVisionToggle(id, false, true, false);
}

NightVision::Infect_Post(id)
{
	nightVisionToggle(id, true, true, false);
	g_hasNightVision[id] = false;
}

NightVision::PlayerPreThink(id)
{
	if (g_nightVisionOn[id])
	{
		new Float:currentTime = get_gametime();
		
		if (currentTime >= g_nextScreenFade[id] && currentTime >= g_screenFadeUntil[id])
		{
			if (!is_user_alive(id))
				sendScreenFade(id, 0.5, 0.5, FFADE_IN, {0, 80, 200}, 100);
			else if (isZombie(id))
				sendScreenFade(id, 0.5, 0.5, FFADE_IN, {200, 50, 0}, 90);
			else
				sendScreenFade(id, 0.5, 0.5, FFADE_IN, {40, 200, 40}, 100);
			
			g_nextScreenFade[id] = currentTime + 0.5;
		}
		
		if (!g_playerLight[id][0])
		{
			static Float:nextLightTime[33];
			if (currentTime < nextLightTime[id])
				return;
			
			new Float:origin[3];
			pev(id, pev_origin, origin);
			
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
			write_byte(TE_DLIGHT);
			write_coord_f(origin[0]); // position.x
			write_coord_f(origin[1]); // position.y
			write_coord_f(origin[2]); // position.z
			write_byte(40); // radius in 10's
			write_byte(30); // red
			write_byte(100); // green
			write_byte(30); // blue
			write_byte(3); // life in 0.1's
			write_byte(0) // decay rate in 0.1's
			message_end();
			
			nextLightTime[id] = currentTime + 0.1;
		}
	}
}

public CmdNightVision(id)
{
	new bool:noLag;
	if (!is_user_alive(id) || isZombie(id))
		noLag = true;
	else if (!g_hasNightVision[id])
		return PLUGIN_HANDLED;
	
	g_nightVisionOn[id] = !g_nightVisionOn[id];
	nightVisionToggle(id, g_nightVisionOn[id], noLag, !noLag);
	return PLUGIN_HANDLED;
}

public NightVision::ScreenFade(id)
{
	new flags = read_data(3);
	if (flags != FFADE_STAYOUT)
	{
		new Float:fadeTime = read_data(1) / float(1 << 12);
		new Float:holdTime = read_data(2) / float(1 << 12);
		
		g_screenFadeUntil[id] = get_gametime() + fadeTime + holdTime;
	}
	else
	{
		g_screenFadeUntil[id] = get_gametime() + 999999.0;
	}
}

public NightVision::LightStyle(style, const light[])
{
	copy(g_defaultLight, charsmax(g_defaultLight), light);
}

public FixLightStyle(taskid)
{
	new id = taskid - TASK_LIGHT;
	sendLightStyle(id, 0, g_light);
}

stock nightVisionToggle(id, bool:toggle, bool:light=false, bool:sound=false)
{
	if (toggle)
	{
		if (light)
			setPlayerLight(id, "#");
		
		if (sound)
			emit_sound(id, CHAN_ITEM, "items/nvg_on.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		g_nextScreenFade[id] = get_gametime();
		g_nightVisionOn[id] = true;
	}
	else
	{
		if (light)
			resetPlayerLight(id);
		
		if (sound)
			emit_sound(id, CHAN_ITEM, "items/nvg_off.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		g_nightVisionOn[id] = false;
	}
}

stock setPlayerLight(id, const light[])
{
	copy(g_playerLight[id], charsmax(g_playerLight[]), light);
	sendLightStyle(id, 0, light);
}

stock resetPlayerLight(id)
{
	g_playerLight[id][0] = 0;
	sendLightStyle(id, 0, g_light);
}

stock setMapLight(const light[])
{
	if (!light[0])
		copy(g_light, charsmax(g_light), g_defaultLight);
	else
		copy(g_light, charsmax(g_light), light);
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_connected(i))
		{
			if (g_playerLight[i][0])
				sendLightStyle(i, 0, g_playerLight[i]);
			else
				sendLightStyle(i, 0, light);
		}
	}
}

stock bool:hasNightVision(id)
{
	return g_hasNightVision[id];
}

stock setNightVision(id, bool:value)
{
	g_hasNightVision[id] = value;
}