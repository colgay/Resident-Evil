const Float:ARMOR_RATIO = 0.0;
const Float:ARMOR_BONUS = 1.0;

Human::Init()
{
	RegisterHam(Ham_TakeDamage, "player", "Human@TakeDamage");
}

Human::Humanize_Post(id)
{
	set_user_health(id, 100);
	set_pev(id, pev_max_health, 300.0);

	set_user_armor(id, 0);
	setMaxArmor(id, 300.0);
	set_user_gravity(id, 1.0);

	cs_reset_user_model(id);
	
	setResourcePoint(id, 1000);
	setPlayerPoint(id, 1000);
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