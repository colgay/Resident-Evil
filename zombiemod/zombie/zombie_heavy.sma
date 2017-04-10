new g_zombieHeavyId;

HeavyZombie::Precache()
{
	precachePlayerModel("zombie_heavy");
	precache_model("models/resident_evil/v_knife_zombie.mdl");
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
		
		cs_set_user_model(id, "zombie_heavy");

		new name[32] = "Zombie - ";
		getZombieTypeName(g_zombieHeavyId, name[9], charsmax(name) - 9);
		setPlayerClass(id, name);
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
		client_print(0, print_chat, "haha heavy");
		set_pev(id, pev_viewmodel2, "models/resident_evil/v_knife_zombie.mdl");
	}
}

HeavyZombie::KnockBack(id, &Float:power)
{
	if (isHeavyZombie(id))
		power *= 0.5;
}

HeavyZombie::PainShock(id, &Float:modifier)
{
	if (isZombie(id) && isHeavyZombie(id))
		applyPainShock(modifier, 0.5);
}

stock bool:isHeavyZombie(id)
{
	if (getZombieType(id) == g_zombieHeavyId)
		return true;
	
	return false;
}