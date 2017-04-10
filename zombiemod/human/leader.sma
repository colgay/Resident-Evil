new const LEADER_MODELS[][] = {"leader_male", "leader_female"};

new const SOUND_LEADER1_HURT[][] = 
{
	"resident_evil/human/leader/male_hurt1.wav",
	"resident_evil/human/leader/male_hurt2.wav"
};

new const SOUND_LEADER2_HURT[][] = 
{
	"resident_evil/human/leader/female_hurt1.wav",
	"resident_evil/human/leader/female_hurt3.wav"
};

new const SOUND_LEADER1_DIE[][] =
{
	"resident_evil/human/leader/male_die1.wav",
	"resident_evil/human/leader/male_die2.wav"
};

new const SOUND_LEADER2_DIE[][] =
{
	"resident_evil/human/leader/female_die1.wav",
	"resident_evil/human/leader/female_die2.wav"
};

new g_leader[33];

Leader::Precache()
{
	precachePlayerModel(LEADER_MODELS[0]);
	precachePlayerModel(LEADER_MODELS[1]);
	
	precacheSounds(SOUND_LEADER1_HURT, sizeof SOUND_LEADER1_HURT);
	precacheSounds(SOUND_LEADER2_HURT, sizeof SOUND_LEADER2_HURT);
	precacheSounds(SOUND_LEADER1_DIE, sizeof SOUND_LEADER1_DIE);
	precacheSounds(SOUND_LEADER2_DIE, sizeof SOUND_LEADER2_DIE);
}

Leader::Init()
{
	register_clcmd("leader", "CmdLeader");

	RegisterHam(Ham_TakeDamage, "player", "Leader@TakeDamage");
	RegisterHam(Ham_Spawn, "weapon_deagle", "Leader@DeagleSpawn_P", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "Leader@DeagleReload");
}

Leader::EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (is_user_connected(id) && !isZombie(id) && g_leader[id])
	{
		// player/
		if (equal(sample, "player", 6))
		{
			// player/headshot or player/bhit_flesh
			if ((sample[7] == 'h' && sample[11] == 's') || (sample[7] == 'b' && sample[12] == 'f'))
			{
				if (HOOK_RESULT == FMRES_SUPERCEDE)
				{
					if (g_leader[id] == LEADER_MALE)
						emit_sound(id, CHAN_VOICE, SOUND_LEADER1_HURT[random(sizeof SOUND_LEADER1_HURT)], volume, attn, flags, pitch);
					else
						emit_sound(id, CHAN_VOICE, SOUND_LEADER2_HURT[random(sizeof SOUND_LEADER2_HURT)], volume, attn, flags, pitch);

					HOOK_RETURN(FMRES_SUPERCEDE);
				}
			}
			// player/die
			else if (sample[7] == 'd' && sample[9] == 'e')
			{
				if (g_leader[id] == LEADER_MALE)
					emit_sound(id, channel, SOUND_LEADER1_DIE[random(sizeof SOUND_LEADER1_DIE)], volume, attn, flags, pitch);
				else
					emit_sound(id, channel, SOUND_LEADER2_DIE[random(sizeof SOUND_LEADER2_DIE)], volume, attn, flags, pitch);

				HOOK_RETURN(FMRES_SUPERCEDE);
			}
		}
	}

	HOOK_RETURN(FMRES_IGNORED);
}

Leader::Humanize_Post(id)
{
	if (g_leader[id])
	{
		if (g_leader[id] == LEADER_MALE)
		{
			set_user_health(id, 500);
			set_pev(id, pev_max_health, 500.0);
			
			set_user_armor(id, 300);
			setMaxArmor(id, 300.0);
			
			set_user_gravity(id, 0.95);
			
			cs_set_user_model(id, LEADER_MODELS[0]);
		}
		else
		{
			set_user_health(id, 400);
			set_pev(id, pev_max_health, 400.0);
			
			set_user_armor(id, 400);
			setMaxArmor(id, 400.0);
			
			set_user_gravity(id, 0.9);

			cs_set_user_model(id, LEADER_MODELS[1]);
		}
		
		strip_user_weapons(id);

		give_item(id, "weapon_ak47");
		giveWeaponFullAmmo(id, CSW_AK47);
		
		give_item(id, "weapon_deagle");
		
		give_item(id, "weapon_knife");
		
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_smokegrenade");
	
		resetPlayerMaxSpeed(id);

		setResourcePoint(id, 60);
		
		setPlayerClass(id, "Leader");
	}
}

Leader::ResetMaxSpeed_Post(id)
{
	if (!isZombie(id) && g_leader[id])
	{
		if (g_leader[id] == LEADER_MALE)
			set_user_maxspeed(id, get_user_maxspeed(id) * 1.15);
		else
			set_user_maxspeed(id, get_user_maxspeed(id) * 1.175);
	}
}

Leader::WeaponTouch(ent, toucher)
{
	new class[32];
	pev(ent, pev_classname, class, charsmax(class));
	
	new weaponId;
	if (equal(class, "weaponbox"))
		weaponId = getWeaponBoxType(ent);
	else if (equal(class, "armoury_entity"))
		weaponId = cs_get_armoury_type(ent);
	else
		HOOK_RETURN(HAM_IGNORED);
	
	if (weaponId == CSW_AK47 || weaponId == CSW_DEAGLE)
	{
		if (is_user_alive(toucher) && !isZombie(toucher))
		{
			if (!g_leader[toucher])
				HOOK_RETURN(HAM_SUPERCEDE);
		}
	}
	
	HOOK_RETURN(HAM_IGNORED);
}

Leader::Killed_Post(id)
{
	g_leader[id] = false;
}

Leader::Infect_Post(id)
{
	g_leader[id] = false;
}

Leader::Disconnect(id)
{
	g_leader[id] = false;
}

Leader::ResetHuman(id)
{
	g_leader[id] = false;
}

Leader::PainShock(id, &Float:modifier)
{
	if (!isZombie(id) && g_leader[id])
	{
		applyPainShock(modifier, 1.25);
	}
}

Leader::KnifeKnockBack(attacker, &Float:power)
{
	if (getLeader(attacker))
	{
		if (getWeaponAnim(attacker) == KNIFE_STABHIT)
			power = 800.0;
		else
			power = 500.0;
	}
}

public Leader::DeagleReload(ent)
{
	if (!pev_valid(ent))
		return HAM_IGNORED;
	
	new player = getPlayerItemDataEnt(ent, "m_pPlayer");
	if (!is_user_alive(player))
		return HAM_IGNORED;
	
	if (getWeaponData(ent, "m_iClip") >= 1)
	{
		message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, player);
		write_byte(0); // sequence number
		write_byte(pev(player, pev_body)); // weaponmodel bodygroup.
		message_end();

		set_pev(player, pev_weaponanim, 0);
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public Leader::DeagleReload_Post(ent)
{
	if (!pev_valid(ent))
		return;
	
	if (getWeaponData(ent, "m_iClip") >= 1)
	{
		setWeaponData(ent, "m_iClip", 1);
	}
}

public Leader::DeagleSpawn_P(ent)
{
	if (!pev_valid(ent))
		return;
	
	setWeaponData(ent, "m_iDefaultAmmo", 0);
}

public Leader::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!is_user_connected(attacker) || isZombie(attacker) == isZombie(id))
		return;
	
	if (!isZombie(attacker) && getLeader(attacker) && inflictor == attacker && (damageBits & DMG_BULLET))
	{
		if (get_user_weapon(attacker) == CSW_AK47)
		{
			SetHamParamFloat(4, damage * 2.0);
		}
		else if (get_user_weapon(attacker) == CSW_DEAGLE)
		{
			if (getZombieType(id) >= 0)
			{
				SetHamParamFloat(4, damage * 9999.0);
			}
		}
	}
}

public CmdLeader(id)
{
	makeLeader(id, random_num(1, 2));
}

stock getLeader(id)
{
	return g_leader[id];
}

stock setLeader(id, value)
{
	g_leader[id] = value;
}

stock makeLeader(id, sex)
{
	resetHuman(id);
	g_leader[id] = sex;
	humanizePlayer(id);
}