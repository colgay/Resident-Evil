const MORPHEUS_HP = 1500;
const MORPHEUS_HP2 = 750;
const Float:MORPHEUS_GRAVITY = 1.0;
const Float:MORPHEUS_SPEED = 0.875;
new const MORPHEUS_MODEL[] = "zombie_morpheus2";
new const MORPHEUS_VIEW_MODEL[] = "models/resident_evil/v_knife_zombie.mdl";

new g_isMorpheus[33];

Morpheus::Precache()
{
	precachePlayerModel(MORPHEUS_MODEL);
}

Morpheus::Init()
{
	register_clcmd("morpheus", "CmdMorpheus");
	
	RegisterHam(Ham_TakeDamage, "player", "Morpheus@TakeDamage");
}

Morpheus::SetKnifeModel(id)
{
	if (g_isMorpheus[id])
	{
		set_pev(id, pev_viewmodel2, MORPHEUS_VIEW_MODEL);
	}
}

Morpheus::HumanArmorDamage(attacker, &Float:armorRatio, &Float:armorBonus)
{
	if (g_isMorpheus[attacker])
	{
		armorRatio = 1.0;
		armorBonus = 0.0;
	}
}

Morpheus::HumanInfection(attacker)
{
	if (g_isMorpheus[attacker])
		HOOK_RETURN(PLUGIN_HANDLED);
	
	HOOK_RETURN(PLUGIN_CONTINUE);
}

Morpheus::KnockBack(id, &Float:power)
{
	if (g_isMorpheus[id])
	{
		power *= 1.0;
	}
}

Morpheus::PainShock(id, attacker, &Float:modifier)
{
	if (isZombie(id) && g_isMorpheus[id])
	{
		applyPainShock(modifier, 0.5);
	}
	else if (isZombie(attacker) && g_isMorpheus[attacker])
	{
		applyPainShock(modifier, 0.75);
	}
}

Morpheus::Infect(id)
{
	if (g_isMorpheus[id])
		setZombieType(id, ZCLASS_SPECIAL);
}

Morpheus::Infect_Post(id)
{
	if (g_isMorpheus[id])
	{
		set_user_health(id, MORPHEUS_HP + (countHumans() * MORPHEUS_HP2));
		set_pev(id, pev_max_health, float(get_user_health(id)));
		
		set_user_gravity(id, MORPHEUS_GRAVITY);
		
		cs_set_user_model(id, MORPHEUS_MODEL);

		setZombieType(id, ZCLASS_SPECIAL);

		resetPlayerMaxSpeed(id);

		setPlayerClass(id, "Morpheus")
	}
}

Morpheus::ResetMaxSpeed_Post(id)
{
	if (isZombie(id) && g_isMorpheus[id])
	{
		set_user_maxspeed(id, get_user_maxspeed(id) * MORPHEUS_SPEED);
	}
}

Morpheus::ResetZombie(id)
{
	g_isMorpheus[id] = false;
}

Morpheus::BoostPlayer(id, &Float:duration, &Float:speedRatio)
{
	if (g_isMorpheus[id])
		duration = 7.5;
}

public Morpheus::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!is_user_connected(attacker) || isZombie(attacker) == isZombie(id))
		return;
	
	if (isZombie(attacker) && g_isMorpheus[attacker])
	{
		if (inflictor != attacker || !(damageBits & DMG_BULLET))
			return;
		
		if (get_user_weapon(attacker) != CSW_KNIFE)
			return;
		
		if (getWeaponAnim(attacker) == KNIFE_STABHIT)
		{
			set_hudmessage(200, 0, 0, -1.0, 0.25, 0, 0.0, 2.0, 1.0, 1.0, 2);
			show_hudmessage(0, "Morpheus 使用致命一擊!");
			
			SetHamParamFloat(4, 999999.0);
		}
	}
}

public CmdMorpheus(id)
{
	resetZombie(id);
	g_isMorpheus[id] = true;
	infectPlayer(id);
}

stock getMorpheus(id)
{
	return g_isMorpheus[id];
}

stock setMorpheus(id, bool:value)
{
	g_isMorpheus[id] = value;
}