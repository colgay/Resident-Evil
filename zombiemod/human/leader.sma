new const LEADER_MODELS[][] = {"leader_male", "leader_female"};

new g_leader[33];

Leader::Precache()
{
	precachePlayerModel(LEADER_MODELS[0]);
	precachePlayerModel(LEADER_MODELS[1]);
}

Leader::Init()
{
	register_clcmd("leader", "CmdLeader");

	RegisterHam(Ham_TakeDamage, "player", "Leader@TakeDamage");
}

Leader::Humanize_Post(id)
{
	if (g_leader[id])
	{
		if (g_leader[id] == LEADER_MALE)
		{
			set_user_health(id, 500);
			set_pev(id, pev_max_health, 500.0);
			
			set_user_armor(id, 300);
			setMaxArmor(id, 300.0);
			
			set_user_gravity(id, 0.95);
			
			cs_set_user_model(id, LEADER_MODELS[0]);
		}
		else
		{
			set_user_health(id, 400);
			set_pev(id, pev_max_health, 400.0);
			
			set_user_armor(id, 400);
			setMaxArmor(id, 400.0);
			
			set_user_gravity(id, 0.9);

			cs_set_user_model(id, LEADER_MODELS[1]);
		}
		
		strip_user_weapons(id);

		give_item(id, "weapon_ak47");
		giveWeaponFullAmmo(id, CSW_AK47);
		
		give_item(id, "weapon_deagle");
		
		give_item(id, "weapon_knife");
		
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_smokegrenade");
	
		resetPlayerMaxSpeed(id);

		setResourcePoint(id, 60);
		
		setPlayerClass(id, "Leader");
	}
}

Leader::ResetMaxSpeed(id)
{
	if (!isZombie(id) && g_leader[id])
	{
		if (g_leader[id] == LEADER_MALE)
			set_user_maxspeed(id, get_user_maxspeed(id) * 1.15);
		else
			set_user_maxspeed(id, get_user_maxspeed(id) * 1.175);
	}
}

Leader::WeaponTouch(ent, toucher)
{
	if (getWeaponBoxType(ent) == CSW_AK47 || getWeaponBoxType(ent) == CSW_DEAGLE)
	{
		if (is_user_alive(toucher) && !isZombie(toucher))
		{
			if (!g_leader[toucher])
				HOOK_RETURN(HAM_SUPERCEDE);
		}
	}
	
	HOOK_RETURN(HAM_IGNORED);
}

Leader::Killed_Post(id)
{
	g_leader[id] = false;
}

Leader::Infect_Post(id)
{
	g_leader[id] = false;
}

Leader::Disconnect(id)
{
	g_leader[id] = false;
}

Leader::ResetHuman(id)
{
	g_leader[id] = false;
}

public Leader::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!is_user_connected(attacker) || isZombie(attacker) == isZombie(id))
		return;
	
	if (!isZombie(attacker) && getLeader(attacker) && inflictor == attacker && (damageBits & DMG_BULLET))
	{
		if (get_user_weapon(attacker) == CSW_AK47)
		{
			SetHamParamFloat(4, damage * 3.0);
		}
		else if (get_user_weapon(attacker) == CSW_DEAGLE)
		{
			if (getZombieType(id) >= 0)
			{
				SetHamParamFloat(4, damage * 9999.0);
			}
		}
	}
}

public CmdLeader(id)
{
	makeLeader(id, random_num(1, 2));
}

stock getLeader(id)
{
	return g_leader[id];
}

stock setLeader(id, value)
{
	g_leader[id] = value;
}

stock makeLeader(id, sex)
{
	resetHuman(id);
	g_leader[id] = sex;
	humanizePlayer(id);
}