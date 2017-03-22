new g_zombieHeavyId;

HeavyZombie::Precache()
{
	precache_model("models/v_knife_r.mdl");
}

HeavyZombie::Init()
{
	g_zombieHeavyId = registerZombieType("Heavy", "HP+ | Speed-", "heavy", 0);
}

HeavyZombie::Infect_Post(id)
{
	if (isHeavyZombie(id))
	{
		set_user_health(id, 3000);
		set_pev(id, pev_max_health, 3000.0);
		
		set_user_gravity(id, 1.0);
		resetPlayerMaxSpeed(id);
		
		cs_set_user_model(id, "vip");
	}
}

HeavyZombie::ResetMaxSpeed_Post(id)
{
	if (isZombie(id) && isHeavyZombie(id))
	{
		set_user_maxspeed(id, get_user_maxspeed(id) * 0.9);
	}
}

HeavyZombie::SetKnifeModel(id)
{
	if (isHeavyZombie(id))
	{
		set_pev(id, pev_viewmodel2, "models/v_knife_r.mdl");
	}
}

stock bool:isHeavyZombie(id)
{
	return bool:(getZombieType(id) == g_zombieHeavyId);
}