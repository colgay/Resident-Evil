const Float:MAX_PAINSHOCK_TIME = 4.0;

new g_resourcePoint[33];
new g_point[33];
new Float:g_maxArmor[33];
new g_playerClass[33][32];

new Float:g_damageDealt[33];
new g_knifePoint[33];

new Float:g_painShockLastTime[33];
new Float:g_painShock[33];

new OrpheuStruct:g_ppmove;

Player::Init()
{
	register_clcmd("set_painshock", "CmdPainShock");
	
	register_event("ResetHUD", "Player@ResetHUD", "b");
	register_message(get_user_msgid("HideWeapon"), "Player@HideWeapon");

	RegisterHam(Ham_TraceAttack, "player", "Player@TraceAttack");
	RegisterHam(Ham_TakeDamage, "player", "Player@TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "Player@TakeDamage_Post", 1);

	OrpheuRegisterHook(OrpheuGetFunction("PM_Move"), "OnPM_Move");
	OrpheuRegisterHook(OrpheuGetFunction("PM_ReduceTimers"), "OnPM_ReduceTimers");
}

Player::NewRound()
{
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		g_knifePoint[i] = 0;
	}
}

Player::Disconnect(id)
{
	g_knifePoint[id] = 0;
	g_resourcePoint[id] = 0;
	g_point[id] = 0;
	g_maxArmor[id] = 0.0;
	g_playerClass[id][0] = 0;
}

Player::DeathMsg(killer, victim)
{
	if (!is_user_connected(killer) || isZombie(killer) == isZombie(victim))
		return;
	
	if (isZombie(victim))
	{
		new point, rs;
		
		if (getNemesis(victim))
		{
			point = 15;
			rs = 8;
			client_print_color(0, killer, "^3%n ^1殺死 Nemesis ^3%n ^1獲得 15 SP", killer, victim)
		}
		else if (getGmonster(victim))
		{
			point = 17;
			rs = 10;
			client_print_color(0, killer, "^3%n ^1殺死 G-Virus Monster ^3%n ^1獲得 17 SP", killer, victim)
		}
		else
		{
			point = 1;
			rs = 3;
		}
		
		givePlayerReward(killer, point, rs);
	}
	else
	{
		new point;
		
		if (getLeader(victim))
		{
			point = 15;
			client_print_color(0, killer, "^3%n ^1殺死 Leader ^3%n ^1獲得 15 SP", killer, victim)
		}
		else
			point = 2;
		
		givePlayerReward(killer, point);
	}
}

Player::PlayerPreThink(id)
{
	if (is_user_alive(id))
	{
		new Float:currentTime = get_gametime();
		
		if (g_painShock[id] < 0.0)
			g_painShock[id] = 0.0;

		if (g_painShock[id] < 1.0)
			g_painShock[id] += ((currentTime - g_painShockLastTime[id]) / MAX_PAINSHOCK_TIME);

		if (g_painShock[id] > 1.0)
			g_painShock[id] = 1.0

		g_painShockLastTime[id] = get_gametime();
	}
}

public OnPM_Move(OrpheuStruct:ppmove, server)
{
	g_ppmove = ppmove;
}

public OnPM_ReduceTimers()
{
	new id = OrpheuGetStructMember(g_ppmove, "player_index") + 1;
	
	if (is_user_alive(id) && g_painShock[id] < 1.0)
	{
		new Float:maxspeed = Float:OrpheuGetStructMember(g_ppmove, "maxspeed");
		OrpheuSetStructMember(g_ppmove, "maxspeed", maxspeed * g_painShock[id]);
	}
}

public CmdPainShock(id)
{
	new arg[16];
	read_argv(1, arg, charsmax(arg));
	
	g_painShock[id] = str_to_float(arg);
}

public Player::TraceAttack(id, attacker, Float:damage, Float:direction[3], tr, damageBits)
{
	//ha
}

public Player::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!is_user_connected(attacker) || isZombie(attacker) == isZombie(id))
		return;
	
	if (inflictor == attacker && (damageBits & DMG_BULLET))
	{
		g_damageDealt[attacker] += damage;
		
		new Float:require, receive;
		if (isZombie(attacker))
		{
			if (get_user_weapon(attacker) != CSW_KNIFE)
				return;
			
			require = 300.0;
			receive = 1;
		}
		else
		{
			if (get_user_weapon(attacker) == CSW_KNIFE && getWeaponAnim(attacker) == KNIFE_STABHIT && g_knifePoint[attacker] < 30)
			{
				givePlayerReward(attacker, 1);
				g_knifePoint[attacker]++;
				return;
			}
			
			require = 500.0;
			receive = 1;
		}
		
		while (g_damageDealt[attacker] >= require)
		{
			givePlayerReward(attacker, receive);
			g_damageDealt[attacker] -= require;
		}
	}
}

public Player::TakeDamage_Post(id, inflictor, attacker, Float:damage, damageBits)
{
	if (is_user_connected(attacker) && isZombie(attacker) != isZombie(id))
	{
		new Float:modifier = 1.0;
		OnPainShock(id, inflictor, attacker, damage, damageBits, modifier);
		
		if (modifier < g_painShock[id])
			g_painShock[id] = modifier;

		setPlayerDataF(id, "m_flVelocityModifier", 1.0);
		client_print(0, print_chat, "painshock is %f", g_painShock[id]);
	}
}

public Player::HideWeapon(msgid, dest, id)
{
	set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | (1 << 5));
}

public Player::ResetHUD(id)
{
	static msgHideWeapon;
	msgHideWeapon || (msgHideWeapon = get_user_msgid("HideWeapon"));
	
	message_begin(MSG_ONE_UNRELIABLE, msgHideWeapon, _, id);
	write_byte((1 << 5));
	message_end();
}

stock givePlayerReward(id, point=0, rs=0)
{
	static message[64];
	
	if (point > 0)
	{
		formatex(message, charsmax(message), "+ %d SP^n", point);
		addPlayerPoint(id, point);
	}
	
	if (rs > 0)
	{
		format(message, charsmax(message), "%s+ %d RS", message, rs);
		addResourcePoint(id, rs);
	}
	
	if (!message[0])
		return;
	
	set_hudmessage(0, 255, 0, -1.0, 0.8, 0, 0.0, 1.0, 1.0, 1.0, 3);
	show_hudmessage(id, message);
}

stock applyPainShock(&Float:input, Float:ratio)
{
	if (ratio > 1.0)
		input += (1.0 - input) * (ratio - 1.0);
	else
		input *= ratio;
}

stock getPlayerClass(id, output[], len)
{
	copy(output, len, g_playerClass[id]);
}

stock setPlayerClass(id, const class[])
{
	copy(g_playerClass[id], charsmax(g_playerClass[]), class);
}

stock Float:getMaxArmor(id)
{
	return g_maxArmor[id];
}

stock setMaxArmor(id, Float:armor)
{
	g_maxArmor[id] = armor;
}

stock getPlayerPoint(id)
{
	return g_point[id];
}

stock setPlayerPoint(id, value)
{
	g_point[id] = value;
}

stock addPlayerPoint(id, amount)
{
	g_point[id] += amount;
}

stock getResourcePoint(id)
{
	return g_resourcePoint[id];
}

stock setResourcePoint(id, value)
{
	g_resourcePoint[id] = value;
}

stock addResourcePoint(id, amount)
{
	g_resourcePoint[id] += amount;
}