new g_zombieLightId;

LightZombie::Precache()
{
	precachePlayerModel("zombie_light");
	precache_model("models/resident_evil/v_knife_zombie.mdl");
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
		
		cs_set_user_model(id, "zombie_light");

		new name[32] = "Zombie - ";
		getZombieTypeName(g_zombieFastId, name[9], charsmax(name) - 9);
		setPlayerClass(id, name);
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
		set_pev(id, pev_viewmodel2, "models/resident_evil/v_knife_zombie.mdl");
	}
}

LightZombie::KnockBack(id, &Float:power)
{
	if (isLightZombie(id))
		power *= 2.0;
}

stock bool:isLightZombie(id)
{
	if (getZombieType(id) == g_zombieLightId)
		return true;
	
	return false;
}