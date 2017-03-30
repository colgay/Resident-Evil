HudInfo::Init()
{
	set_task(0.5, "UpdateHudInfo", TASK_HUDINFO, _, _, "b");
}

public UpdateHudInfo()
{
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		showHudInfo(i);
	}
}

stock showHudInfo(id)
{
	new player = id;
	if (!is_user_alive(player))
	{
		player = pev(id, pev_iuser2);
		if (!is_user_alive(player))
			return;
	}
	
	new color[3];
	new class[32];
	
	if (isZombie(player))
	{
		if (getNemesis(player))
			color = {255, 0, 0};
		else if (getGmonster(player))
			color = {200, 0, 200};
		else
			color = {200, 100, 0};
	}
	else
	{
		if (getLeader(player))
		{
			if (getLeader(player) == LEADER_MALE)
				color = {0, 50, 200};
			else
				color = {200, 50, 50};
		}
		else
			color = {0, 200, 0};
	}
	
	getPlayerClass(player, class, charsmax(class));
	
	if (id != player)
	{
		set_hudmessage(color[0], color[1], color[2], 0.6, 0.775, 0, 0.0, 0.5, 0.0, 1.0, 4);
		show_hudmessage(id, "HP: %d | AP: %d | %s | SP: %d | RS: %d", 
			get_user_health(player), get_user_armor(player), class, 
			getPlayerPoint(player), getResourcePoint(player));
	}
	else
	{
		set_hudmessage(color[0], color[1], color[2], 0.6, 0.9, 0, 0.0, 0.5, 0.0, 1.0, 4);
		show_hudmessage(id, "HP: %d | AP: %d | %s | SP: %d | RS: %d", 
			get_user_health(id), get_user_armor(id), class, getPlayerPoint(player), getResourcePoint(player));
	}
}