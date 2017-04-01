new const Float:POISON_MAX_DELAY[] = {2.0, 1.25, 1.5};
new const Float:POISON_MIN_DELAY[] = {0.25, 0.1, 0.2};

new bool:g_isZombie[33];

new Array:g_zombieName;
new Array:g_zombieDesc;
new Array:g_zombieClass;
new Array:g_zombieFlags;
new g_zombieCount;

new g_zombieType[33];
new g_nextZombieType[33];

new g_poisonType[33];
new Float:g_poisonLevel[33];
new g_poisonAttacker[33];
new Float:g_lastPoisonTime[33];

new bool:g_killedByInfection[33];

Zombie::Precache()
{
	g_zombieName = ArrayCreate(32);
	g_zombieDesc = ArrayCreate(32);
	g_zombieClass = ArrayCreate(32);
	g_zombieFlags = ArrayCreate(1);
	
	precache_model("models/v_knife_r.mdl");
}

Zombie::Init()
{
	register_clcmd("choosezombie", "CmdChooseZombie");
	
	RegisterHam(Ham_TakeDamage, "player", "Zombie@TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "Zombie@TakeDamage_Post", 1);
}

Zombie::PlayerPreThink(id)
{
	if (is_user_alive(id) && !isZombie(id) && g_poisonType[id])
	{
		new Float:currentTime = get_gametime();
		
		new v = g_poisonType[id]-1;

		new Float:delay = POISON_MAX_DELAY[v] - ((POISON_MAX_DELAY[v] - POISON_MIN_DELAY[v]) * g_poisonLevel[id]);
		if (currentTime < g_lastPoisonTime[id] + delay)
			return;
		
		new health = get_user_health(id);
		if (health - 1 <= 0)
		{
			infectPlayer(id, g_poisonAttacker[id], true);
			return;
		}
		
		set_user_health(id, health - 1);
		sendDamage(id, 0, 0, DMG_NERVEGAS, Float:{0.0, 0.0, 0.0});
		
		switch (g_poisonType[id])
		{
			case POISON_T_VIRUS:
				sendScreenFade(id, 1.0, 0.0, FFADE_IN, {0, 200, 0}, 150, true);
			case POISON_N_VIRUS:
				sendScreenFade(id, 1.0, 0.0, FFADE_IN, {200, 0, 200}, 150, true);
			case POISON_G_VIRUS:
				sendScreenFade(id, 1.0, 0.0, FFADE_IN, {100, 0, 200}, 150, true);
		}
		
		g_lastPoisonTime[id] = currentTime;
	}
}

Zombie::Infect_Post(id)
{
	if (g_zombieType[id] >= 0)
	{
		g_zombieType[id] = g_nextZombieType[id];
		
		if (g_zombieType[id] == -1)
		{
			g_zombieType[id] = 0;
			ShowZombieTypeMenu(id);
		}
	}
	
	set_user_health(id, 1000);
	set_pev(id, pev_max_health, 1000.0);
	set_user_gravity(id, 1.0);
	set_user_armor(id, 0);

	resetPlayerMaxSpeed(id);

	//cs_set_user_model(id, "vip");
	
	setPlayerClass(id, "Zombie");
	
	dropWeapons(id, 0);
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");

	resetPoisoning(id);
}

Zombie::TouchWeapon(toucher)
{
	if (is_user_alive(toucher) && g_isZombie[toucher])
		HOOK_RETURN(HAM_SUPERCEDE);
	
	HOOK_RETURN(HAM_IGNORED);
}

Zombie::KnifeDeploy_Post(id)
{
	if (g_isZombie[id])
	{
		OnSetZombieKnifeModel(id);
	}
}

Zombie::SetKnifeModel(id)
{
	set_pev(id, pev_weaponmodel2, "");
}

Zombie::Disconnect(id)
{
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (g_poisonAttacker[i] == id)
			g_poisonAttacker[i] = 0;
	}

	resetZombie(id);
	resetPoisoning(id);
}

Zombie::Killed(id)
{
	resetPoisoning(id);
}

Zombie::Killed_Post(id)
{
	resetZombie(id);
}

Zombie::Humanize_Post(id)
{
	resetZombie(id);
	resetPoisoning(id);
}

public Zombie::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!pev_valid(id))
		return;
	
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return;
	
	g_killedByInfection[id] = false;

	if (is_user_connected(attacker) && isZombie(attacker) && !isZombie(id) && inflictor == attacker)
	{
		new Float:health;
		pev(id, pev_health, health);
		
		if (damage >= health)
		{
			if (OnHumanInfection(id, attacker, damage) != PLUGIN_HANDLED)
			{
				g_killedByInfection[id] = true;
				set_pev(id, pev_health, health + damage);
			}
		}
		
		if (damage > 0.0)
		{
			if (OnAddPoison(id, attacker, damage) != PLUGIN_HANDLED)
				addPoison(id, attacker, POISON_T_VIRUS, damage * 0.002);
		}
	}
}

public Zombie::TakeDamage_Post(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!pev_valid(id))
		return;
	
	if (g_killedByInfection[id])
	{
		g_killedByInfection[id] = false;

		infectPlayer(id, attacker, true);
		set_pev(id, pev_health, get_user_health(id) * 0.5);
	}
}

public CmdChooseZombie(id)
{
	ShowZombieTypeMenu(id);
	return PLUGIN_HANDLED;
}

public ShowZombieTypeMenu(id)
{
	new menu = menu_create("Choose your zombie type", "HandleZombieTypeMenu");
	new buffer[64]	

	for (new i = 0; i < g_zombieCount; i++)
	{
		if (g_nextZombieType[id] == i)
		{
			formatex(buffer, charsmax(buffer), "\d%a %a", 
					ArrayGetStringHandle(g_zombieName, i), 
					ArrayGetStringHandle(g_zombieDesc, i));
		}
		else
		{
			formatex(buffer, charsmax(buffer), "\w%a \y%a", 
					ArrayGetStringHandle(g_zombieName, i), 
					ArrayGetStringHandle(g_zombieDesc, i));
		}
		
		menu_additem(menu, buffer);
	}
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y");
	menu_display(id, menu);
}

public HandleZombieTypeMenu(id, menu, item)
{
	menu_destroy(menu);
	
	if (item == MENU_EXIT)
		return;
	
	g_nextZombieType[id] = item;
	client_print(id, print_chat, "Your next zombie type will be: %a", ArrayGetStringHandle(g_zombieName, item));
}

stock addPoison(id, attacker, type, Float:amount)
{
	g_poisonType[id] = type;
	g_poisonAttacker[id] = attacker;
	g_lastPoisonTime[id] = get_gametime();
	g_poisonLevel[id] = floatclamp(g_poisonLevel[id] + amount, 0.0, 1.0);
	
	switch (g_poisonType[id])
	{
		case POISON_T_VIRUS:
			set_user_rendering(id, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 1);
		case POISON_N_VIRUS:
			set_user_rendering(id, kRenderFxGlowShell, 200, 0, 200, kRenderNormal, 1);
		case POISON_G_VIRUS:
			set_user_rendering(id, kRenderFxGlowShell, 100, 0, 200, kRenderNormal, 1);
	}
}

stock resetPoisoning(id)
{
	g_poisonType[id] = 0;
	g_poisonAttacker[id] = 0;
	g_poisonLevel[id] = 0.0;
	
	if (is_user_alive(id))
		set_user_rendering(id);
}

stock Float:getPoisonLevel(id)
{
	return g_poisonLevel[id];
}

stock setPoisonLevel(id, Float:value)
{
	g_poisonLevel[id] = value;
}

stock getPoisonType(id)
{
	return g_poisonType[id];
}

stock infectPlayer(id, attacker=0, bool:score=false)
{
	OnPlayerInfect(id, attacker);
	
	if (score)
	{
		if (is_user_connected(attacker) && id != attacker)
		{
			set_user_frags(attacker, get_user_frags(attacker) + 1);
			updateScoreInfo(attacker);
		}

		setPlayerData(id, "m_iDeaths", getPlayerData(id, "m_iDeaths") + 1);
		updateScoreInfo(id);

		sendDeathMsg(attacker, id, 0, "infection");
		setScoreAttrib(id, 0);
	}
	
	g_isZombie[id] = true;

	OnPlayerInfect_Post(id, attacker);
}

stock registerZombieType(const name[], const desc[], const class[], flags)
{
	ArrayPushString(g_zombieName, name);
	ArrayPushString(g_zombieDesc, desc);
	ArrayPushString(g_zombieClass, class);
	ArrayPushCell(g_zombieFlags, flags);
	
	g_zombieCount++;
	return g_zombieCount - 1;
}

stock getZombieTypeName(index, output[], len)
{
	ArrayGetString(g_zombieName, index, output, len);
}

stock setZombieType(id, type)
{
	g_zombieType[id] = type;
}

stock getZombieType(id)
{
	return g_zombieType[id];
}

stock bool:isZombie(id)
{
	return g_isZombie[id];
}

stock setZombie(id, bool:value)
{
	g_isZombie[id] = value;
}

stock resetZombie(id)
{
	g_isZombie[id] = false;
	g_zombieType[id] = 0;
	
	OnResetZombie(id);
}

stock countZombies()
{
	new count = 0;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_alive(i))
			continue;
		
		if (isZombie(i))
			count++;
	}
	
	return count;
}

stock countDeadZombies()
{
	new count = 0;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_alive(i))
			continue;
		
		if (isZombie(i))
			count++;
	}
	
	return count;
}