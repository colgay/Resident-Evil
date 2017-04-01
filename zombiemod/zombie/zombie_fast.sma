new g_zombieFastId;

FastZombie::Precache()
{
	precachePlayerModel("zombie_fast");
	precache_model("models/resident_evil/v_knife_zombie.mdl");
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
		
		cs_set_user_model(id, "zombie_fast");

		new name[32] = "Zombie - ";
		getZombieTypeName(g_zombieFastId, name[9], charsmax(name) - 9);
		setPlayerClass(id, name);
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
		set_pev(id, pev_viewmodel2, "models/resident_evil/v_knife_zombie.mdl");
	}
}

FastZombie::KnockBack(id, &Float:power)
{
	if (isFastZombie(id))
		power *= 1.5;
}

stock bool:isFastZombie(id)
{
	if (getZombieType(id) == g_zombieFastId)
		return true;
	
	return false;
}