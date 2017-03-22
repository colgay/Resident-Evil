new g_zombieFastId;

FastZombie::Precache()
{
	precache_model("models/v_knife_r.mdl");
}

FastZombie::Init()
{
	g_zombieFastId = registerZombieType("Fast", "Speed+ | HP-", "fast", 0);
}

FastZombie::Infect_Post(id)
{
	if (isFastZombie(id))
	{
		set_user_health(id, 1000);
		set_pev(id, pev_max_health, 1000.0);
		
		set_user_gravity(id, 1.0);
		resetPlayerMaxSpeed(id);
		
		cs_set_user_model(id, "vip");
	}
}

FastZombie::ResetMaxSpeed_Post(id)
{
	if (isZombie(id) && isFastZombie(id))
	{
		set_user_maxspeed(id, get_user_maxspeed(id) * 1.2);
	}
}

FastZombie::SetKnifeModel(id)
{
	if (isFastZombie(id))
	{
		set_pev(id, pev_viewmodel2, "models/v_knife_r.mdl");
	}
}

stock bool:isFastZombie(id)
{
	return bool:(getZombieType(id) == g_zombieFastId);
}