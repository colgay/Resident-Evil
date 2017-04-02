new const PRIMARY_NAMES[][] = {"MAC-10", "TMP", "Scout"};
new const PRIMARY_CLASSES[][] = {"mac10", "tmp", "scout"};

new const PISTOL_NAMES[][] = {"Glock 18", "USP", "P228", "Dual Elite", "Five-Seven"};
new const PISTOL_CLASSES[][] = {"glock18", "usp", "p228", "elite", "fiveseven"};

const Float:ARMOR_RATIO = 0.0;
const Float:ARMOR_BONUS = 1.0;

new Float:g_attackDirection[3];
new Float:g_oldVelocity[3];

Human::Init()
{
	RegisterHam(Ham_TraceAttack, "player", "Human@TraceAttack");
	RegisterHam(Ham_TraceAttack, "player", "Human@TraceAttack_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "Human@TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "Human@TakeDamage_Post", 1);
}

Human::Humanize_Post(id)
{
	set_user_health(id, 100);
	set_pev(id, pev_max_health, 300.0);

	set_user_armor(id, 0);
	setMaxArmor(id, 300.0);
	set_user_gravity(id, 1.0);

	cs_reset_user_model(id);
	
	setResourcePoint(id, 40);
	
	setPlayerClass(id, "Survivor");
	
	ShowPrimaryMenu(id);
}

Human::PainShock(id, Float:damage, &Float:modifier)
{
	if (!isZombie(id))
	{
		//new Float:dmgMultiplier = 1.0;
		new hitGroup = get_ent_data(id, "CBaseMonster", "m_LastHitGroup");
		
		switch (hitGroup)
		{
			case HIT_HEAD:
			{
				applyPainShock(modifier, 0.5);
				//dmgMultiplier = 4.0;
			}
			case HIT_CHEST:
			{
				applyPainShock(modifier, 0.75);
			}
			case HIT_STOMACH:
			{
				applyPainShock(modifier, 0.6);
				//dmgMultiplier = 1.25
			}
			case HIT_LEFTLEG, HIT_RIGHTLEG:
			{
				applyPainShock(modifier, 0.4);
				//dmgMultiplier = 0.75;
			}
			default:
			{
				applyPainShock(modifier, 0.65);
			}
		}
		
		// If player has armor
		if (damage == 0.0)
			applyPainShock(modifier, 1.3);
	}
}

Human::KnifeKnockBack(id, attacker, &Float:power)
{
	if (!isZombie(attacker) && getWeaponAnim(attacker) == KNIFE_STABHIT && getZombieType(id) >= 0)
		power = 700.0;
}

public Human::TraceAttack(id, attacker, Float:damage, Float:direction[3], trace, damageBits)
{
	if (!pev_valid(id))
		return;
	
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return;

	g_attackDirection = direction;
}

public Human::TraceAttack_Post(id, attacker, Float:damage, Float:direction[3], trace, damageBits)
{
}

public Human::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!pev_valid(id))
		return;
	
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return;
	
	if (is_user_connected(attacker) && isZombie(attacker) && !isZombie(id) && inflictor == attacker)
	{
		new Float:armor;
		pev(id, pev_armorvalue, armor);
		
		if (armor > 0.0)
		{
			new Float:armorRatio = ARMOR_RATIO;
			new Float:armorBonus = ARMOR_BONUS;

			OnHumanArmorDamage(id, attacker, damage, armorRatio, armorBonus);
			
			new Float:newDamage = armorRatio * damage;
			new Float:armorDamage = (damage - newDamage) * armorBonus;
			
			if (armorDamage > armor)
			{
				armorDamage -= armor;
				armorDamage *= (1 / armorBonus);
				newDamage += armorDamage;
				
				set_pev(id, pev_armorvalue, 0.0);
			}
			else
			{
				set_pev(id, pev_armorvalue, armor - armorDamage);
			}
			
			if (newDamage < 1)
			{
				new Float:origin[3];
				ExecuteHam(Ham_EyePosition, attacker, origin);
				sendDamage(id, 0, 1, damageBits, origin);
			}
			
			damage = newDamage;			
			SetHamParamFloat(4, damage);
		}
	}
	
	pev(id, pev_velocity, g_oldVelocity);
}

public Human::TakeDamage_Post(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!pev_valid(id) || !is_user_connected(attacker))
		return;
	
	if (inflictor == attacker && (damageBits & DMG_BULLET))
	{
		set_pev(id, pev_velocity, g_oldVelocity);
		
		if (isZombie(id) && !isZombie(attacker))
		{
			new Float:velocity[3];
			pev(id, pev_velocity, velocity);
			
			new Float:vector[3];
			vector = g_attackDirection;
			
			new Float:angles[3];
			vector_to_angle(vector, angles);
			angles[0] = 0.0;
			angle_vector(angles, ANGLEVECTOR_FORWARD, vector);
			
			new Float:power = 0.0;
			if (get_user_weapon(attacker) == CSW_KNIFE)
			{
				OnKnifeKnockBack(id, attacker, damage, power);
			}
			else
			{
				power = WEAPON_KNOCKBACK[get_user_weapon(attacker)];
				OnKnockBack(id, attacker, damage, power);
			}
			
			if (~pev(id, pev_flags) & FL_ONGROUND)
				power *= 0.25;
			
			//client_print(0, print_chat, "real power is %f", power);
			
			xs_vec_mul_scalar(vector, power, vector);

			velocity[0] += vector[0];
			velocity[1] += vector[1];
			velocity[2] += vector[2];
			
			set_pev(id, pev_velocity, velocity);
		}
	}
}

public ShowPrimaryMenu(id)
{
	new menu = menu_create("Choose a Weapon", "HandlePrimaryMenu");
	
	for (new i = 0; i < sizeof PRIMARY_NAMES; i++)
	{
		menu_additem(menu, PRIMARY_NAMES[i]);
	}
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y");
	menu_setprop(menu, MPROP_EXITNAME, "#bye#^n");
	menu_display(id, menu, _, 10);
}

public HandlePrimaryMenu(id, menu, item)
{
	menu_destroy(menu);
	
	if (item == MENU_EXIT)
		return;
	
	if (!is_user_alive(id) || isZombie(id))
		return;
	
	dropWeapons(id, 1);
	
	new name[32] = "weapon_"
	add(name, charsmax(name), PRIMARY_CLASSES[item]);	
	give_item(id, name);
	
	new weapon = get_weaponid(name);
	giveWeaponFullAmmo(id, weapon);
	
	ShowPistolMenu(id);
}

public ShowPistolMenu(id)
{
	new menu = menu_create("Choose a Pistol", "HandlePistolMenu");
	
	for (new i = 0; i < sizeof PISTOL_NAMES; i++)
	{
		menu_additem(menu, PISTOL_NAMES[i]);
	}
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y");
	menu_setprop(menu, MPROP_EXITNAME, "#bye#^n");
	menu_display(id, menu, _, 10);
}

public HandlePistolMenu(id, menu, item)
{
	menu_destroy(menu);
	
	if (item == MENU_EXIT)
		return;
	
	if (!is_user_alive(id) || isZombie(id))
		return;
	
	dropWeapons(id, 2);
	
	new name[32] = "weapon_"
	add(name, charsmax(name), PISTOL_CLASSES[item]);	
	give_item(id, name);
	
	new weapon = get_weaponid(name);
	giveWeaponFullAmmo(id, weapon);
}

stock resetHuman(id)
{
	OnResetHuman(id);
}

stock humanizePlayer(id)
{
	OnPlayerHumanize(id);
	setZombie(id, false);
	OnPlayerHumanize_Post(id);
}

stock countHumans()
{
	new count = 0;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_alive(i))
			continue;
		
		if (!isZombie(i))
			count++;
	}
	
	return count;
}