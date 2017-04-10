new const SOUND_ZOMBIE_HURT[][] = 
{
	"resident_evil/zombie/hurt1.wav",
	"resident_evil/zombie/hurt2.wav",
	"resident_evil/zombie/hurt3.wav"
};

new const SOUND_ZOMBIE_DIE[][] = 
{
	"resident_evil/zombie/die1.wav",
	"resident_evil/zombie/die2.wav",
	"resident_evil/zombie/die3.wav"
};

new const SOUND_ZOMBIE_INFECT[][] = 
{
	"resident_evil/zombie/infect1.wav",
	"resident_evil/zombie/infect2.wav"
};

new const SOUND_ZOMBIE_HIT[][] =
{
	"resident_evil/zombie/hit1.wav",
	"resident_evil/zombie/hit2.wav",
	"resident_evil/zombie/hit3.wav"
};

new const SOUND_ZOMBIE_HITWALL[] =
{
	"resident_evil/zombie/hitwall.wav"
};

new const SOUND_ZOMBIE_MISS[][] =
{
	"resident_evil/zombie/miss1.wav",
	"resident_evil/zombie/miss2.wav"
};

new const SOUND_ZOMBIE_BOOST[] = "resident_evil/zombie/boost.wav";

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

new Float:g_boost[33];
new bool:g_hasNoDamage[33];

new bool:g_killedByInfection[33];

Zombie::Precache()
{
	g_zombieName = ArrayCreate(32);
	g_zombieDesc = ArrayCreate(32);
	g_zombieClass = ArrayCreate(32);
	g_zombieFlags = ArrayCreate(1);
	
	precache_model("models/v_knife_r.mdl");
	
	precacheSounds(SOUND_ZOMBIE_HURT, sizeof SOUND_ZOMBIE_HURT);
	precacheSounds(SOUND_ZOMBIE_DIE, sizeof SOUND_ZOMBIE_DIE);
	precacheSounds(SOUND_ZOMBIE_INFECT, sizeof SOUND_ZOMBIE_INFECT);
	precacheSounds(SOUND_ZOMBIE_HIT, sizeof SOUND_ZOMBIE_HIT);
	precache_sound(SOUND_ZOMBIE_HITWALL);
	precacheSounds(SOUND_ZOMBIE_MISS, sizeof SOUND_ZOMBIE_MISS);
	precache_sound(SOUND_ZOMBIE_BOOST);
}

Zombie::Init()
{
	register_clcmd("choosezombie", "CmdChooseZombie");
	register_clcmd("drop", "CmdZombieDrop");

	RegisterHam(Ham_TraceAttack, "player", "Zombie@TraceAttack");
	RegisterHam(Ham_TakeDamage, "player", "Zombie@TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "Zombie@TakeDamage_Post", 1);
	
	set_task(1.0, "TaskAddZombieArmor", TASK_ADDARMOR, _, _, "b");
}

Zombie::PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return;

	if (isZombie(id))
	{
		if (g_zombieType[id] == ZCLASS_BOSS)
		{
			static Float:lastFootprintTime[33];
			
			if (get_gametime() < lastFootprintTime[id] + 0.7)
				return;
			
			if (getEntSpeed(id) < 120)
				return;

			if (~pev(id, pev_flags) & FL_ONGROUND)
				return;
			
			new Float:origin[3];
			pev(id, pev_origin, origin);
			
			if (pev(id, pev_bInDuck) == 1)
				origin[2] -= 18.0;
			else
				origin[2] -= 36.0;
			
			static const decals[] = {99 , 107 , 108 , 184 , 185 , 186 , 187 , 188 , 189};

			message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, origin);
			write_byte(TE_WORLDDECAL);
			write_coord_f(origin[0]);
			write_coord_f(origin[1]);
			write_coord_f(origin[2]);
			write_byte(decals[random(sizeof decals)]);
			message_end();
			
			lastFootprintTime[id] = get_gametime();
		}
	}
	else if (g_poisonType[id])
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
	
		emit_sound(id, CHAN_BODY, SOUND_HUMAN_HEARTBEAT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
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

Zombie::EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (is_user_connected(id) && isZombie(id))
	{
		// player/
		if (equal(sample, "player", 6))
		{
			// player/headshot or player/bhit_flesh
			if ((sample[7] == 'h' && sample[11] == 's') || (sample[7] == 'b' && sample[12] == 'f'))
			{
				if (random_num(1, 4) == 1)
				{
					emit_sound(id, CHAN_VOICE, SOUND_ZOMBIE_HURT[random(sizeof SOUND_ZOMBIE_HURT)], volume, attn, flags, pitch);
					HOOK_RETURN(FMRES_SUPERCEDE);
				}
			}
			// player/die
			else if (sample[7] == 'd' && sample[9] == 'e')
			{
				emit_sound(id, channel, SOUND_ZOMBIE_DIE[random(sizeof SOUND_ZOMBIE_DIE)], volume, attn, flags, pitch);
				HOOK_RETURN(FMRES_SUPERCEDE);
			}
		}
		// weapons/knife_
		else if (equal(sample, "weapons", 7) && sample[8] == 'k' && sample[11] == 'f')
		{
			// weapons/knife_hit or weapons/knife_stab
			if (sample[14] == 'h' || (sample[14] == 's' && sample[17] == 'b'))
			{
				// weapons/knife_hitwall
				if (sample[17] == 'w')
					emit_sound(id, channel, SOUND_ZOMBIE_HITWALL, volume, attn, flags, pitch);
				else
					emit_sound(id, channel, SOUND_ZOMBIE_HIT[random(sizeof SOUND_ZOMBIE_HIT)], volume, attn, flags, pitch);
				
				HOOK_RETURN(FMRES_SUPERCEDE);
			}
			// weapons/knife_slash
			else if (sample[14] == 's')
			{
				emit_sound(id, channel, SOUND_ZOMBIE_MISS[random(sizeof SOUND_ZOMBIE_MISS)], volume, attn, flags, pitch);
				HOOK_RETURN(FMRES_SUPERCEDE);
			}
		}
	}

	HOOK_RETURN(FMRES_IGNORED);
}

Zombie::Infect_Post(id, attacker)
{
	if (is_user_connected(attacker))
	{
		emit_sound(id, CHAN_VOICE, SOUND_ZOMBIE_INFECT[random(sizeof SOUND_ZOMBIE_INFECT)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	
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

Zombie::PlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		if (isZombie(id))
			setNoDamage(id, 3.0);
	}
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
	resetPoisoning(id, false);
	removePlayerBoost(id, false);
	removeNoDamage(id, false);
}

Zombie::Killed(id)
{
	resetPoisoning(id);
	removePlayerBoost(id, true);
	removeNoDamage(id, true);
}

Zombie::Killed_Post(id)
{
	resetZombie(id);
}

Zombie::Humanize_Post(id)
{
	resetZombie(id);
	resetPoisoning(id);
	removePlayerBoost(id, true);
	removeNoDamage(id, true);
}

Zombie::ResetMaxSpeed_Post(id)
{
	if (isZombie(id) && g_boost[id] > 0.0)
		set_user_maxspeed(id, get_user_maxspeed(id) * g_boost[id]);
}

Zombie::GiveDefaultItems(id)
{
	if (isZombie(id))
	{
		strip_user_weapons(id);
		HOOK_RETURN(OrpheuSupercede);
	}

	HOOK_RETURN(OrpheuIgnored);
}

Zombie::PainShock(id, inflictor, attacker, damageBits, &Float:modifier)
{
	if (isZombie(id))
	{
		if (inflictor == attacker && (damageBits & DMG_BULLET))
			applyPainShock(modifier, WEAPON_PAINSHOCK[get_user_weapon(attacker)]);

		//new Float:dmgMultiplier = 1.0;
		new hitGroup = get_ent_data(id, "CBaseMonster", "m_LastHitGroup");
		
		switch (hitGroup)
		{
			case HIT_HEAD:
			{
				applyPainShock(modifier, 0.65);
				//dmgMultiplier = 4.0;
			}
			case HIT_CHEST:
			{
				applyPainShock(modifier, 0.9);
			}
			case HIT_STOMACH:
			{
				applyPainShock(modifier, 0.75);
				//dmgMultiplier = 1.25
			}
			case HIT_LEFTLEG, HIT_RIGHTLEG:
			{
				applyPainShock(modifier, 0.5);
				//dmgMultiplier = 0.75;
			}
			default:
			{
				applyPainShock(modifier, 0.9);
			}
		}
		
		if (g_boost[id] > 0.0)
			applyPainShock(modifier, 1.75);
	}
}

Zombie::KnockBack(id, &Float:power)
{
	if (isZombie(id) && g_boost[id] > 0.0)
		power *= 0.5;
}

public Zombie::TraceAttack(id, attacker, Float:damage, Float:direction[3], trace, damageBits)
{
	if (!pev_valid(id))
		return HAM_IGNORED;
	
	if (g_hasNoDamage[id])
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public Zombie::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!pev_valid(id))
		return HAM_IGNORED;
	
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_IGNORED;

	if (g_hasNoDamage[id])
		return HAM_SUPERCEDE;
	
	g_killedByInfection[id] = false;

	if (is_user_connected(attacker) && isZombie(attacker) != isZombie(id) && inflictor == attacker)
	{
		if (!isZombie(id))
		{
			new Float:health;
			pev(id, pev_health, health);
			
			if (damage >= health)
			{
				humanInfection(id, attacker, damage);
			}
			
			if (damage > 0.0)
			{
				if (OnAddPoison(id, attacker, damage) != PLUGIN_HANDLED)
					addPoison(id, attacker, POISON_T_VIRUS, damage * 0.002);
			}
		}
		else
		{
			new Float:armor;
			pev(id, pev_armorvalue, armor);

			if (getZombieType(id) == ZCLASS_BOSS)
				armor += damage * 0.05;
			else
				armor += damage * 0.1;
			
			set_pev(id, pev_armorvalue, armor);
		}
	}
	
	return HAM_IGNORED;
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

public CmdZombieDrop(id)
{
	if (is_user_alive(id) && isZombie(id))
	{
		new Float:armor;
		pev(id, pev_armorvalue, armor);

		if (armor < 100)
		{
			client_print(id, print_center, "你的 AP 未滿 100");
			return PLUGIN_HANDLED;
		}
		
		if (g_boost[id] > 0.0)
		{
			client_print(id, print_center, "暴衝狀態中...")
			return PLUGIN_HANDLED;
		}
		
		if (OnZombieBoost(id) == PLUGIN_HANDLED)
			return PLUGIN_HANDLED;
		
		boostPlayer(id, 5.0, 1.3);
		set_pev(id, pev_armorvalue, armor - 100.0);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public ShowZombieTypeMenu(id)
{
	new menu = menu_create("Choose Your Zombie Type", "HandleZombieTypeMenu");
	new buffer[64]	

	for (new i = 0; i < g_zombieCount; i++)
	{
		if (g_nextZombieType[id] == i)
		{
			formatex(buffer, charsmax(buffer), "\\d%a %a", 
					ArrayGetStringHandle(g_zombieName, i), 
					ArrayGetStringHandle(g_zombieDesc, i));
		}
		else
		{
			formatex(buffer, charsmax(buffer), "\\w%a \\y%a", 
					ArrayGetStringHandle(g_zombieName, i), 
					ArrayGetStringHandle(g_zombieDesc, i));
		}
		
		menu_additem(menu, buffer);
	}
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\\y");
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

public TaskAddZombieArmor()
{
	new Float:armor;
	
	for (new id = 1; id <= g_maxClients; id++)
	{
		if (!is_user_alive(id) || !isZombie(id))
			continue;
		
		if (getZombieType(id) <= ZCLASS_SPECIAL)
		{
			pev(id, pev_armorvalue, armor)
			set_pev(id, pev_armorvalue, floatmin(armor + 1.0, 300.0));
		}
	}
}

public RemovePlayerBoost(taskid)
{
	new id = taskid - TASK_BOOST;
	removePlayerBoost(id, true);
}

public RemovePlayerNoDamage(taskid)
{
	new id = taskid - TASK_NODAMAGE;
	removeNoDamage(id, true);
}

stock setNoDamage(id, Float:duration)
{
	g_hasNoDamage[id] = true;
	
	if (getNemesis(id))
		set_user_rendering(id, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 16);
	else if (getGmonster(id))
		set_user_rendering(id, kRenderFxGlowShell, 200, 0, 200, kRenderNormal, 16);
	else
		set_user_rendering(id, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16);

	remove_task(id + TASK_NODAMAGE);
	set_task(duration, "RemovePlayerNoDamage", id + TASK_NODAMAGE);
}

stock removeNoDamage(id, bool:effects=true)
{
	if (!g_hasNoDamage[id])
		return;
	
	g_hasNoDamage[id] = false;
	remove_task(id + TASK_NODAMAGE);

	if (effects)
		set_user_rendering(id);
}

stock boostPlayer(id, Float:duration, Float:speedRatio)
{
	OnBoostPlayer(id, duration, speedRatio);

	g_boost[id] = speedRatio;
	resetPlayerMaxSpeed(id);
	
	if (getNemesis(id))
		set_user_rendering(id, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 16);
	else if (getGmonster(id))
		set_user_rendering(id, kRenderFxGlowShell, 200, 0, 200, kRenderNormal, 16);
	else
		set_user_rendering(id, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16);

	emit_sound(id, CHAN_VOICE, SOUND_ZOMBIE_BOOST, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	remove_task(id + TASK_BOOST);
	set_task(duration, "RemovePlayerBoost", id + TASK_BOOST);
}

stock removePlayerBoost(id, bool:effects=true)
{
	if (g_boost[id] <= 0.0)
		return;
	
	g_boost[id] = 0.0;
	remove_task(id + TASK_BOOST);
	
	if (effects)
	{
		resetPlayerMaxSpeed(id);
		set_user_rendering(id);
	}
}

stock humanInfection(id, attacker, Float:damage)
{
	if (OnHumanInfection(id, attacker, damage) == PLUGIN_HANDLED)
		return;
	
	g_killedByInfection[id] = true;
	set_pev(id, pev_health, float(get_user_health(id)) + 999999.0);
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

stock resetPoisoning(id, bool:effects=true)
{
	if (!g_poisonType[id])
		return;

	g_poisonType[id] = 0;
	g_poisonAttacker[id] = 0;
	g_poisonLevel[id] = 0.0;
	
	if (effects)
	{
		set_user_rendering(id);
	}
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