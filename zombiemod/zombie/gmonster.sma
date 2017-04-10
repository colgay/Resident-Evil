new const GMONSTER_HP[3]  = {3000, 2750, 3500};
new const GMONSTER_HP2[3] = {1200, 1000, 1400};
new const Float:GMONSTER_GRAVITY[3] = {0.95, 0.9, 0.7};
new const Float:GMONSTER_SPEED[3] = {0.95, 1.05, 1.2};
new const GMONSTER_MODEL[3][] = {"birkin", "birkin_2", "birkin_3"};

new const GMONSTER_VIEW_MODEL[3][] = 
{
	"models/resident_evil/v_knife_birkin.mdl",
	"models/resident_evil/v_knife_birkin2.mdl",
	"models/resident_evil/v_knife_birkin3.mdl"
};

new const SOUND_GVM_HURT[][] = 
{
	"resident_evil/zombie/gmonster/hurt1.wav",
	"resident_evil/zombie/gmonster/hurt2.wav",
	"resident_evil/zombie/gmonster/hurt3.wav"
};

new const SOUND_GVM_DIE[][] = 
{
	"resident_evil/zombie/gmonster/die1.wav",
	"resident_evil/zombie/gmonster/die2.wav"
};

new const SOUND_GVM_HIT[][] = 
{
	"resident_evil/zombie/gmonster/hit1.wav",
	"resident_evil/zombie/gmonster/hit2.wav"
};

new const SOUND_GVM_HITWALL[] = 
{
	"resident_evil/zombie/gmonster/hitwall.wav"
};

new const SOUND_GVM_MISS[][] =
{
	"resident_evil/zombie/gmonster/claw_miss_1.wav",
	"resident_evil/zombie/gmonster/claw_miss_2.wav"
};


const Float:G1_MUTATION_RATIO = 0.25;
const Float:G2_MUTATION_RATIO = 0.35;

new g_gmonster[33];

Gmonster::Precache()
{
	precachePlayerModel(GMONSTER_MODEL[0]);
	precachePlayerModel(GMONSTER_MODEL[1]);
	precachePlayerModel(GMONSTER_MODEL[2]);
	
	precacheModels(GMONSTER_VIEW_MODEL, sizeof GMONSTER_VIEW_MODEL);
	
	precacheSounds(SOUND_GVM_HURT, sizeof SOUND_GVM_HURT);
	precacheSounds(SOUND_GVM_DIE, sizeof SOUND_GVM_DIE);
	precacheSounds(SOUND_GVM_HIT, sizeof SOUND_GVM_HIT);
	precache_sound(SOUND_GVM_HITWALL);
	precacheSounds(SOUND_GVM_MISS, sizeof SOUND_GVM_MISS);
}

Gmonster::Init()
{
	RegisterHam(Ham_TakeDamage, "player", "Gmonster@TakeDamage");
	
	register_clcmd("gmonster", "CmdGmonster");
}

Gmonster::HumanInfection(attacker)
{
	if (g_gmonster[attacker] && g_gmonster[attacker] != GMONSTER_2ND)
		HOOK_RETURN(PLUGIN_HANDLED);
	
	HOOK_RETURN(PLUGIN_CONTINUE);
}

Gmonster::PlayerPreThink(id)
{
	if (is_user_alive(id) && isZombie(id) && g_gmonster[id])
	{
		if (g_gmonster[id] == GMONSTER_1ST)
		{
			if (get_user_health(id) <= pev(id, pev_max_health) * G1_MUTATION_RATIO)
			{				
				g_gmonster[id]++;
				infectPlayer(id);
				setNoDamage(id, 3.0);

				set_hudmessage(200, 0, 100, -1.0, 0.2, 1, 0.0, 3.0, 1.0, 1.0, 1);
				show_hudmessage(0, "G-2 Detected!");

				playSound(0, SOUND_WARNING);
			}
		}
		else
		{
			if (g_gmonster[id] == GMONSTER_2ND)
			{
				if (get_user_health(id) <= pev(id, pev_max_health) * G2_MUTATION_RATIO)
				{				
					g_gmonster[id]++;
					infectPlayer(id);
					setNoDamage(id, 3.0);

					set_hudmessage(200, 0, 100, -1.0, 0.2, 1, 0.0, 3.0, 1.0, 1.0, 1);
					show_hudmessage(0, "G-3 Detected!");
					
					playSound(0, SOUND_WARNING);
				}
			}
			
			// Receive virus bomb every x seconds
			if (!user_has_weapon(id, CSW_HEGRENADE))
			{
				if (get_gametime() >= getLastVirusBombThrowTime(id) + 25.0)
					give_item(id, "weapon_hegrenade");
			}
		}
	}
}

Gmonster::ResetMaxSpeed_Post(id)
{
	if (isZombie(id) && g_gmonster[id])
	{
		new g = g_gmonster[id]-1;
		set_user_maxspeed(id, get_user_maxspeed(id) * GMONSTER_SPEED[g]);
	}
}

Gmonster::SetKnifeModel(id)
{
	if (g_gmonster[id])
	{
		new g = g_gmonster[id]-1;
		set_pev(id, pev_viewmodel2, GMONSTER_VIEW_MODEL[g]);
		
		client_print(0, print_chat, "is...gg");
	}
}

Gmonster::ResetZombie(id)
{
	g_gmonster[id] = false;
}

Gmonster::Infect(id)
{
	if (g_gmonster[id])
		setZombieType(id, ZCLASS_BOSS);
}

Gmonster::Infect_Post(id)
{
	if (g_gmonster[id])
	{
		new g = g_gmonster[id]-1;
		
		set_user_health(id, GMONSTER_HP[g] + (countHumans() * GMONSTER_HP2[g]));
		set_pev(id, pev_max_health, float(get_user_health(id)));
		
		set_user_gravity(id, GMONSTER_GRAVITY[g]);
		resetPlayerMaxSpeed(id);

		cs_set_user_model(id, GMONSTER_MODEL[g]);
		
		if (g_gmonster[id] > GMONSTER_1ST)
			give_item(id, "weapon_hegrenade");

		new class[32];
		formatex(class, charsmax(class), "G-%d", g + 1);
		setPlayerClass(id, class)
	}
}

Gmonster::BoostPlayer(id, &Float:duration, &Float:speedRatio)
{
	if (g_gmonster[id])
		duration = 6.0;
}

Gmonster::KnockBack(id, &Float:power)
{
	switch (g_gmonster[id])
	{
		case GMONSTER_1ST:
			power *= 0.9;
		case GMONSTER_2ND:
			power *= 0.6;
		case GMONSTER_3RD:
			power *= 0.4;
	}
}

Gmonster::PainShock(id, attacker, &Float:modifier)
{
	if (isZombie(id) && g_gmonster[id])
	{
		switch (g_gmonster[id])
		{
			case GMONSTER_1ST:
				applyPainShock(modifier, 0.9);
			case GMONSTER_2ND:
				applyPainShock(modifier, 1.15);
			default:
				applyPainShock(modifier, 1.35);
		}
	}
	else if (isZombie(attacker) && getNemesis(attacker))
	{
		switch (g_gmonster[id])
		{
			case GMONSTER_1ST:
				applyPainShock(modifier, 0.7);
			case GMONSTER_2ND:
				applyPainShock(modifier, 0.9);
			default:
				applyPainShock(modifier, 0.75);
		}
	}
}

Gmonster::AddPoison(id, attacker, Float:damage)
{
	if (g_gmonster[attacker])
	{
		addPoison(id, attacker, POISON_G_VIRUS, damage * 0.0027);
		HOOK_RETURN(PLUGIN_HANDLED);
	}
	
	HOOK_RETURN(PLUGIN_CONTINUE);
}

Gmonster::HumanArmorDamage(attacker, &Float:armorRatio, &Float:armorBonus)
{
	if (g_gmonster[attacker] == GMONSTER_3RD)
	{
		armorRatio = 0.5;
		armorBonus = 0.5;
	}
}

Gmonster::EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (is_user_connected(id) && isZombie(id) && g_gmonster[id])
	{
		// player/
		if (equal(sample, "player", 6))
		{
			// player/headshot or player/bhit_flesh
			if ((sample[7] == 'h' && sample[11] == 's') || (sample[7] == 'b' && sample[12] == 'f'))
			{
				if (HOOK_RESULT == FMRES_SUPERCEDE)
				{
					emit_sound(id, CHAN_VOICE, SOUND_GVM_HURT[random(sizeof SOUND_GVM_HURT)], volume, attn, flags, pitch);
					HOOK_RETURN(FMRES_SUPERCEDE);
				}
			}
			// player/die
			else if (sample[7] == 'd' && sample[9] == 'e')
			{
				emit_sound(id, channel, SOUND_GVM_DIE[random(sizeof SOUND_GVM_DIE)], volume, attn, flags, pitch);
				HOOK_RETURN(FMRES_SUPERCEDE);
			}
		}
		// weapons/knife_
		else if (equal(sample, "weapons", 7) && sample[8] == 'k' && sample[11] == 'f')
		{
			// weapons/knife_hit or weapons/knife_stab
			if (sample[14] == 'h' || (sample[14] == 's' && sample[17] == 'b'))
			{
				// weapons/knife_hitwall
				if (sample[17] == 'w')
					emit_sound(id, channel, SOUND_GVM_HITWALL, volume, attn, flags, pitch);
				else
					emit_sound(id, channel, SOUND_GVM_HIT[random(sizeof SOUND_GVM_HIT)], volume, attn, flags, pitch);
				
				HOOK_RETURN(FMRES_SUPERCEDE);
			}
			// weapons/knife_slash
			else if (sample[14] == 's')
			{
				emit_sound(id, channel, SOUND_GVM_MISS[random(sizeof SOUND_GVM_MISS)], volume, attn, flags, pitch);
				HOOK_RETURN(FMRES_SUPERCEDE);
			}
		}
	}

	HOOK_RETURN(FMRES_IGNORED);
}

public Gmonster::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!is_user_connected(attacker) || isZombie(attacker) == isZombie(id))
		return;
	
	if (isZombie(attacker) && g_gmonster[attacker])
	{
		if (inflictor != attacker || !(damageBits & DMG_BULLET))
			return;
		
		if (get_user_weapon(attacker) != CSW_KNIFE)
			return;
		
		switch (g_gmonster[attacker])
		{
			case GMONSTER_1ST:
			{
				if (getWeaponAnim(attacker) == KNIFE_STABHIT)
				{
					set_hudmessage(200, 0, 200, -1.0, 0.25, 0, 0.0, 3.0, 1.0, 1.0, 2);
					show_hudmessage(0, "G-1 使用致命一擊!");
					
					SetHamParamFloat(4, 999999.0);
				}
			}
			case GMONSTER_2ND:
			{
				if (damage > 0.0 && pev(id, pev_armorvalue) <= 0)
				{
					humanInfection(id, attacker, damage);
				}
			}
			case GMONSTER_3RD:
			{
				SetHamParamFloat(4, damage * 3.0);
			}
		}
	}
}

public CmdGmonster(id)
{
	resetZombie(id);
	g_gmonster[id] = GMONSTER_1ST;
	infectPlayer(id);
}

stock getGmonster(id)
{
	return g_gmonster[id];
}

stock setGmonster(id, value)
{
	g_gmonster[id] = value;
}