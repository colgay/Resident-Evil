const COMBINER_HP = 2000;
const COMBINER_HP2 = 850;
const Float:COMBINER_GRAVITY = 0.95;
const Float:COMBINER_SPEED = 1.0;
new const COMBINER_MODEL[] = "zombie_combiner2";
new const COMBINER_VIEW_MODEL[] = "models/resident_evil/v_knife_zombie.mdl";

new g_isCombiner[33];

Combiner::Precache()
{
	precachePlayerModel(COMBINER_MODEL);
}

Combiner::Init()
{
	register_clcmd("combiner", "CmdCombiner");
}

Combiner::PlayerPreThink(id)
{
	if (is_user_alive(id) && isZombie(id) && g_isCombiner[id])
	{
		// Receive virus bomb every x seconds
		if (!user_has_weapon(id, CSW_HEGRENADE))
		{
			if (get_gametime() >= getLastVirusBombThrowTime(id) + 25.0)
				give_item(id, "weapon_hegrenade");
		}
	}
}

Combiner::SetKnifeModel(id)
{
	if (g_isCombiner[id])
	{
		set_pev(id, pev_viewmodel2, COMBINER_VIEW_MODEL);
	}
}

Combiner::HumanArmorDamage(attacker, &Float:armorRatio, &Float:armorBonus)
{
	if (g_isCombiner[attacker])
	{
		armorRatio = 0.5;
		armorBonus = 0.5;
	}
}

Combiner::KnockBack(id, &Float:power)
{
	if (g_isCombiner[id])
	{
		power *= 0.8;
	}
}

Combiner::PainShock(id, attacker, &Float:modifier)
{
	if (isZombie(id) && g_isCombiner[id])
	{
		applyPainShock(modifier, 1.1);
	}
	else if (isZombie(attacker) && g_isCombiner[attacker])
	{
		applyPainShock(modifier, 0.9);
	}
}

Combiner::Infect(id)
{
	if (g_isCombiner[id])
		setZombieType(id, ZCLASS_SPECIAL);
}

Combiner::Infect_Post(id)
{
	if (g_isCombiner[id])
	{
		set_user_health(id, COMBINER_HP + (countHumans() * COMBINER_HP2));
		set_pev(id, pev_max_health, float(get_user_health(id)));
		
		set_user_gravity(id, COMBINER_GRAVITY);
		
		cs_set_user_model(id, COMBINER_MODEL);

		setZombieType(id, ZCLASS_SPECIAL);

		resetPlayerMaxSpeed(id);

		setPlayerClass(id, "Combiner")
	}
}

Combiner::ResetMaxSpeed_Post(id)
{
	if (isZombie(id) && g_isCombiner[id])
	{
		set_user_maxspeed(id, get_user_maxspeed(id) * COMBINER_SPEED);
	}
}

Combiner::ResetZombie(id)
{
	g_isCombiner[id] = false;
}

public CmdCombiner(id)
{
	resetZombie(id);
	g_isCombiner[id] = true;
	infectPlayer(id);
}

stock getCombiner(id)
{
	return g_isCombiner[id];
}

stock setCombiner(id, bool:value)
{
	g_isCombiner[id] = value;
}