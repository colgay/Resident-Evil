new g_zombieLightId;

LightZombie::Precache()
{
	precache_model("models/v_knife_r.mdl");
}

LightZombie::Init()
{
	g_zombieLightId = registerZombieType("Light", "Jump+ | HP-", "light", 0);
}

LightZombie::Infect_Post(id)
{
	if (isLightZombie(id))
	{
		set_user_health(id, 1500);
		set_pev(id, pev_max_health, 1500.0);
		
		set_user_gravity(id, 0.6);
		resetPlayerMaxSpeed(id);
		
		cs_set_user_model(id, "vip");
	}
}

LightZombie::ResetMaxSpeed_Post(id)
{
	if (isZombie(id) && isLightZombie(id))
	{
		set_user_maxspeed(id, get_user_maxspeed(id) * 0.95);
	}
}

LightZombie::SetKnifeModel(id)
{
	if (isLightZombie(id))
	{
		set_pev(id, pev_viewmodel2, "models/v_knife_r.mdl");
	}
}

stock bool:isLightZombie(id)
{
	return bool:(getZombieType(id) == g_zombieLightId);
}