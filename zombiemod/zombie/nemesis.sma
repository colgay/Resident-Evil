new const NEMESIS_HP[] = {3000, 3250};
new const NEMESIS_HP2[] = {1200, 1000};
new const Float:NEMESIS_GRAVITY[] = {0.95, 0.6};
new const Float:NEMESIS_SPEED[] = {1.05, 1.2};
new const NEMESIS_MODEL[][] = {"nemesis", "nemesis_2"};

new const NEMESIS_VIEW_MODEL[][] = 
{
	"models/resident_evil/v_knife_nemesis.mdl", 
	"models/resident_evil/v_knife_zombie.mdl"
};

new const NEMESIS_P_MODEL[] = "models/resident_evil/p_knife_nemesis.mdl";

new const SOUND_NEMESIS_HURT[][] = 
{
	"resident_evil/zombie/nemesis/hurt1.wav",
	"resident_evil/zombie/nemesis/hurt2.wav",
	"resident_evil/zombie/nemesis/hurt3.wav"
};

new const SOUND_NEMESIS_DIE[][] = 
{
	"resident_evil/zombie/nemesis/die1.wav",
	"resident_evil/zombie/nemesis/die2.wav"
};

new const SOUND_N1_HIT[] = 
{
	"resident_evil/zombie/nemesis/punch.wav"
};

new const SOUND_N2_HIT[][] = 
{
	"resident_evil/zombie/nemesis/hit1.wav",
	"resident_evil/zombie/nemesis/hit2.wav"
};

new const SOUND_NEMESIS_HITWALL[] = 
{
	"resident_evil/zombie/nemesis/punch.wav"
};

new const SOUND_N1_MISS[][] =
{
	"resident_evil/zombie/nemesis/miss1.wav",
	"resident_evil/zombie/nemesis/miss2.wav"
};

new const SOUND_N2_MISS[][] =
{
	"resident_evil/zombie/nemesis/miss3.wav",
	"resident_evil/zombie/nemesis/miss4.wav"
};

const Float:NEMESIS_MUTATION_RATIO = 0.25;

const Float:NEMESIS_ROCKET_RADIUS = 280.0;
const Float:NEMESIS_ROCKET_DAMAGE = 350.0;
const Float:NEMESIS_ROCKET_DELAY = 30.0;
const Float:NEMESIS_ROCKET_SPEED = 1000.0;

new g_nemesis[33];

new Float:g_rocketLastLaunch;
new bool:g_isRocketReloaded;

Nemesis::Precache()
{
	precachePlayerModel(NEMESIS_MODEL[0]);
	precachePlayerModel(NEMESIS_MODEL[1]);

	precacheModels(NEMESIS_VIEW_MODEL, sizeof NEMESIS_VIEW_MODEL);
	precache_model(NEMESIS_P_MODEL);

	precacheSounds(SOUND_NEMESIS_HURT, sizeof SOUND_NEMESIS_HURT);
	precacheSounds(SOUND_NEMESIS_DIE, sizeof SOUND_NEMESIS_DIE);
	precache_sound(SOUND_N1_HIT);
	precacheSounds(SOUND_N2_HIT, sizeof SOUND_N2_HIT);
	precache_sound(SOUND_NEMESIS_HITWALL);
	precacheSounds(SOUND_N1_MISS, sizeof SOUND_N1_MISS);
	precacheSounds(SOUND_N2_MISS, sizeof SOUND_N2_MISS);

	precache_model("models/rpgrocket.mdl");
	precache_sound("weapons/c4_explode1.wav");
	precache_sound("weapons/rocketfire1.wav");
}

Nemesis::Init()
{
	register_clcmd("nemesis", "CmdNemesis");
	
	register_touch("rpgrocket", "*", "Nemesis@RocketTouch");
	register_think("rpgrocket", "Nemesis@RocketThink");
	
	RegisterHam(Ham_TakeDamage, "player", "Nemesis@TakeDamage");
}

Nemesis::NewRound()
{
	new ent = FM_NULLENT;
	while ((ent = find_ent_by_class(ent, "rpgrocket")) != 0)
	{
		if (pev_valid(ent))
			remove_entity(ent);
	}
}

Nemesis::PlayerPreThink(id)
{
	if (is_user_alive(id) && isZombie(id) && g_nemesis[id] == NEMESIS_1ST)
	{
		if (get_user_health(id) <= pev(id, pev_max_health) * NEMESIS_MUTATION_RATIO)
		{
			g_nemesis[id]++;
			infectPlayer(id);
			
			set_hudmessage(255, 0, 0, -1.0, 0.2, 1, 0.0, 3.0, 1.0, 1.0, 1);
			show_hudmessage(0, "N-2 Detected!");
			
			playSound(0, SOUND_WARNING);
		}
	}
}

Nemesis::CmdStart(id, uc)
{
	if (is_user_alive(id) && isZombie(id) && g_nemesis[id] == NEMESIS_1ST && get_user_weapon(id) == CSW_KNIFE)
	{
		new buttons = get_uc(uc, UC_Buttons);
		if (buttons & IN_ATTACK)
		{
			buttons &= ~IN_ATTACK;
			buttons |= IN_ATTACK2;
			
			set_uc(uc, UC_Buttons, buttons);
		}
		
		if (!g_isRocketReloaded)
		{
			if (get_gametime() >= g_rocketLastLaunch + NEMESIS_ROCKET_DELAY)
			{
				g_isRocketReloaded = true;
				client_print(0, print_center, "Nemesis' Rocket Launcher has been reloaded!");
			}
		}
		else if ((buttons & IN_USE) && (~pev(id, pev_oldbuttons) & IN_USE))
		{
			nemesisRocketLaunch(id);
		}
	}
}

Nemesis::SetKnifeModel(id)
{
	if (g_nemesis[id])
	{
		if (g_nemesis[id] == NEMESIS_1ST)
		{
			set_pev(id, pev_viewmodel2, NEMESIS_VIEW_MODEL[0]);
			set_pev(id, pev_weaponmodel2, NEMESIS_P_MODEL);
		}
		else if (g_nemesis[id] == NEMESIS_2ND)
		{
			set_pev(id, pev_viewmodel2, NEMESIS_VIEW_MODEL[1]);
		}
	}
}

Nemesis::HumanArmorDamage(attacker, &Float:armorRatio, &Float:armorBonus)
{
	if (g_nemesis[attacker])
	{
		armorRatio = 1.0;
		armorBonus = 0.0;
	}
}

Nemesis::HumanInfection(attacker)
{
	if (g_nemesis[attacker])
		HOOK_RETURN(PLUGIN_HANDLED);
	
	HOOK_RETURN(PLUGIN_CONTINUE);
}

Nemesis::BoostPlayer(id, &Float:duration, &Float:speedRatio)
{
	if (g_nemesis[id])
		duration = 6.0;
}

Nemesis::AddPoison(id, attacker, Float:damage)
{
	if (g_nemesis[attacker])
	{
		addPoison(id, attacker, POISON_N_VIRUS, damage * 0.003);
		HOOK_RETURN(PLUGIN_HANDLED);
	}
	
	HOOK_RETURN(PLUGIN_CONTINUE);
}

Nemesis::KnockBack(id, &Float:power)
{
	switch (g_nemesis[id])
	{
		case NEMESIS_1ST:
			power *= 0.3;
		case NEMESIS_2ND:
			power *= 0.5;
	}
}

Nemesis::PainShock(id, attacker, &Float:modifier)
{
	if (isZombie(id) && g_nemesis[id])
	{
		if (g_nemesis[id] == NEMESIS_1ST)
			applyPainShock(modifier, 1.4);
		else
			applyPainShock(modifier, 1.275);
	}
	else if (isZombie(attacker) && g_nemesis[attacker])
	{
		if (g_nemesis[attacker] == NEMESIS_1ST)
			applyPainShock(modifier, 0.7);
		else
			applyPainShock(modifier, 0.8);
	}
}

Nemesis::Infect(id)
{
	if (g_nemesis[id])
		setZombieType(id, ZCLASS_BOSS);
}

Nemesis::Infect_Post(id)
{
	if (g_nemesis[id])
	{
		new n = g_nemesis[id] - 1;
		
		set_user_health(id, NEMESIS_HP[n] + (countHumans() * NEMESIS_HP2[n]));
		set_pev(id, pev_max_health, float(get_user_health(id)));
		
		set_user_gravity(id, NEMESIS_GRAVITY[n]);
		
		cs_set_user_model(id, NEMESIS_MODEL[n]);

		setZombieType(id, ZCLASS_BOSS);

		resetPlayerMaxSpeed(id);
		
		g_isRocketReloaded = true;
	
		new class[32];
		formatex(class, charsmax(class), "N-%d", n + 1);
		setPlayerClass(id, class)
	}
}

Nemesis::ResetMaxSpeed_Post(id)
{
	if (isZombie(id) && g_nemesis[id])
	{
		new n = g_nemesis[id] - 1;
		set_user_maxspeed(id, get_user_maxspeed(id) * NEMESIS_SPEED[n]);
	}
}

Nemesis::ResetZombie(id)
{
	g_nemesis[id] = false;
}

Nemesis::EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (is_user_connected(id) && isZombie(id) && g_nemesis[id])
	{
		// player/
		if (equal(sample, "player", 6))
		{
			// player/headshot or player/bhit_flesh
			if ((sample[7] == 'h' && sample[11] == 's') || (sample[7] == 'b' && sample[12] == 'f'))
			{
				if (HOOK_RESULT == FMRES_SUPERCEDE)
				{
					emit_sound(id, CHAN_VOICE, SOUND_NEMESIS_HURT[random(sizeof SOUND_NEMESIS_HURT)], volume, attn, flags, pitch);
					HOOK_RETURN(FMRES_SUPERCEDE);
				}
			}
			// player/die
			else if (sample[7] == 'd' && sample[9] == 'e')
			{
				emit_sound(id, channel, SOUND_NEMESIS_DIE[random(sizeof SOUND_NEMESIS_DIE)], volume, attn, flags, pitch);
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
					emit_sound(id, channel, SOUND_NEMESIS_HITWALL, volume, attn, flags, pitch);
				else
				{
					if (g_nemesis[id] == NEMESIS_1ST)
						emit_sound(id, channel, SOUND_N1_HIT, volume, attn, flags, pitch);
					else
						emit_sound(id, channel, SOUND_N2_HIT[random(sizeof SOUND_N2_HIT)], volume, attn, flags, pitch);
				}

				HOOK_RETURN(FMRES_SUPERCEDE);
			}
			// weapons/knife_slash
			else if (sample[14] == 's')
			{
				if (g_nemesis[id] == NEMESIS_1ST)
					emit_sound(id, channel, SOUND_N1_MISS[random(sizeof SOUND_N1_MISS)], volume, attn, flags, pitch);
				else
					emit_sound(id, channel, SOUND_N2_MISS[random(sizeof SOUND_N2_MISS)], volume, attn, flags, pitch);

				HOOK_RETURN(FMRES_SUPERCEDE);
			}
		}
	}

	HOOK_RETURN(FMRES_IGNORED);
}

public Nemesis::TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!is_user_connected(attacker) || isZombie(attacker) == isZombie(id))
		return;
	
	if (isZombie(attacker) && g_nemesis[attacker])
	{
		if (inflictor != attacker || (~damageBits & DMG_BULLET))
			return;
		
		if (get_user_weapon(attacker) != CSW_KNIFE)
			return;
		
		if (g_nemesis[attacker] == NEMESIS_2ND)
		{
			if (getWeaponAnim(attacker) == KNIFE_STABHIT)
			{
				if (random_num(1, 2) == 1)
				{
					set_hudmessage(200, 0, 0, -1.0, 0.25, 0, 0.0, 3.0, 1.0, 1.0, 2);
					show_hudmessage(0, "N-2 使用致命一擊!");
					
					SetHamParamFloat(4, 999999.0);
				}
			}
		}
	}
}

public CmdNemesis(id)
{
	resetZombie(id);
	g_nemesis[id] = true;
	infectPlayer(id);
}

public Nemesis::RocketTouch(rocket, toucher)
{
	if (pev_valid(rocket))
		nemesisRocketExplode(rocket, toucher);
}

public Nemesis::RocketThink(rocket)
{
	if (pev_valid(rocket))
		remove_entity(rocket);
}

stock nemesisRocketLaunch(id)
{	
	// Create rocket entity
	new ent = create_entity("info_target");
	if (pev_valid(ent))
	{
		// Set punch angle
		new Float:vector[3];
		pev(id, pev_punchangle, vector);

		vector[0] -= random_float(5.0, 10.0);
		vector[1] += random_float(-2.5, 2.5);
		vector[2] += random_float(-2.5, 2.5);
		
		set_pev(id, pev_punchangle, vector);
		
		// Play fire sound
		emit_sound(id, CHAN_WEAPON, "weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

		g_isRocketReloaded = false;
		g_rocketLastLaunch = get_gametime();

		entity_set_model(ent, "models/rpgrocket.mdl");
		entity_set_size(ent, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});

		set_pev(ent, pev_classname, "rpgrocket");
		//set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_LIGHT);
		set_pev(ent, pev_movetype, MOVETYPE_FLY);
		set_pev(ent, pev_owner, id);
		set_pev(ent, pev_solid, SOLID_BBOX);
		
		ExecuteHam(Ham_EyePosition, id, vector);
		entity_set_origin(ent, vector);
		
		pev(id, pev_angles, vector);
		set_pev(ent, pev_angles, vector);
		
		velocity_by_aim(id, floatround(NEMESIS_ROCKET_SPEED), vector);
		set_pev(ent, pev_velocity, vector);
		
		set_pev(ent, pev_nextthink, get_gametime() + 15.0);
		
		// Make trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(ent); // entity
		write_short(g_sprTrail); // sprite
		write_byte(10); // life
		write_byte(5); // width
		write_byte(100); // r
		write_byte(100); // g
		write_byte(100); // b
		write_byte(200); // brightness
		message_end();
	}
}

stock nemesisRocketExplode(rocket, toucher)
{
	new attacker = pev(rocket, pev_owner);
	
	new Float:origin[3];
	pev(rocket, pev_origin, origin);
	
	new ent = FM_NULLENT;
	new Float:takeDamage;
	new Float:radius, Float:ratio;
	new Float:damage, damageBits;
	
	while ((ent = find_ent_in_sphere(ent, origin, NEMESIS_ROCKET_RADIUS)) != 0)
	{
		if (!pev_valid(ent))
			continue;
		
		if (!is_user_alive(ent))
			continue;
		
		// Not damageable
		pev(ent, pev_takedamage, takeDamage);
		if (takeDamage == DAMAGE_NO)
			continue;
		
		radius = entity_range(rocket, ent);
		ratio  = (1.0 - radius / NEMESIS_ROCKET_RADIUS);
		damage = ratio * NEMESIS_ROCKET_DAMAGE;
		damageBits = DMG_GRENADE;
		
		if (ent == toucher)
			damage = NEMESIS_ROCKET_DAMAGE;
		
		if (ratio >= 0.85)
			damageBits |= DMG_ALWAYSGIB;
		
		// Not human
		if (isZombie(ent))
			continue;
		
		ExecuteHamB(Ham_TakeDamage, ent, rocket, attacker, damage, damageBits);
	}
	
	// Make explosion
	message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
	write_byte(TE_EXPLOSION);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + 30.0);
	write_short(g_sprFExplo); // spr
	write_byte(25); // scale
	write_byte(30); // framerate
	write_byte(TE_EXPLFLAG_NONE); // flags
	message_end();
	
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_EXPLOSION);
	write_coord_f(origin[0] + random_float(-64.0, 64.0));
	write_coord_f(origin[1] + random_float(-64.0, 64.0));
	write_coord_f(origin[2] + 30.0);
	write_short(g_sprEExplo); // spr
	write_byte(30); // scale
	write_byte(30); // framerate
	write_byte(TE_EXPLFLAG_NOSOUND); // flags
	message_end();
	
	// Make shockwave
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_BEAMCYLINDER); // TE id
	write_coord_f(origin[0]); // x
	write_coord_f(origin[1]); // y
	write_coord_f(origin[2] + 20.0); // z
	write_coord_f(origin[0]); // x axis
	write_coord_f(origin[1]); // y axis
	write_coord_f(origin[2] + 400.0); // z axis
	write_short(g_sprShockwave); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(5); // life
	write_byte(30); // width
	write_byte(0); // noise
	write_byte(150); // red
	write_byte(150); // green
	write_byte(150); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();
	
	// Play sound
	emit_sound(rocket, CHAN_WEAPON, "weapons/c4_explode1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

	remove_entity(rocket);
}

stock getNemesis(id)
{
	return g_nemesis[id];
}

stock setNemesis(id, value)
{
	g_nemesis[id] = value;
}