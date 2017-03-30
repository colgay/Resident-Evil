const NADE_FIREBOMB = 9817;

const Float:FIREBOMB_RADIUS = 240.0;
const Float:FIREBOMB_DURATION_MIN = 15.0;
const Float:FIREBOMB_DURATION_MAX = 7.5;
const Float:FIREBOMB_DAMAGE = 75.0;
const Float:FIREBOMB_UPDATE_TIME = 0.5;

new const SOUND_FIREBOMB_EXPLODE[] = "weapons/mortarhit.wav"

new bool:g_isBurning[33];
new g_burnAttacker[33];
new Float:g_burnStart[33];
new Float:g_burnDuration[33];

FireBomb::Precache()
{
	//ha
	precache_sound(SOUND_FIREBOMB_EXPLODE);
}

FireBomb::SetModel(ent, const model[])
{
	if (equal(model[7], "w_hegrenade.mdl"))
	{
		new Float:dmgTime;
		pev(ent, pev_dmgtime, dmgTime);
		
		if (dmgTime == 0.0)
			return;
		
		new owner = pev(ent, pev_owner);
		if (isZombie(owner))
			return;
		
		set_pev(ent, PEV_NADE_TYPE, NADE_FIREBOMB);
	}
}

FireBomb::GrenadeThink(ent)
{
	if (!pev_valid(ent))
		HOOK_RETURN(HAM_IGNORED);
	
	if (pev(ent, PEV_NADE_TYPE) == NADE_FIREBOMB)
	{
		new Float:dmgTime;
		pev(ent, pev_dmgtime, dmgTime);
		
		if (dmgTime > get_gametime())
			HOOK_RETURN(HAM_IGNORED);
		
		fireBombExplode(ent);
		HOOK_RETURN(HAM_SUPERCEDE);
	}
	
	HOOK_RETURN(HAM_IGNORED);
}

FireBomb::PlayerPreThink(id)
{
	if (g_isBurning[id] && isZombie(id))
	{
		new Float:currentTime = get_gametime();
		
		new Float:origin[3];
		pev(id, pev_origin, origin);
		
		if ((pev(id, pev_flags) & FL_INWATER) || currentTime >= g_burnStart[id] + g_burnDuration[id])
		{
			resetPlayerBurning(id, true);
			return;
		}
		
		static Float:lastUpdateTime[33]
		if (currentTime < lastUpdateTime[id] + FIREBOMB_UPDATE_TIME)
			return;
		
		// Make fire sprite
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_SPRITE); // TE id
		write_coord_f(origin[0]+random_float(-5.0, 5.0)); // x
		write_coord_f(origin[1]+random_float(-5.0, 5.0)); // y
		write_coord_f(origin[2]+random_float(-10.0, 10.0)); // z
		write_short(g_sprFire); // sprite
		write_byte(random_num(5, 10)); // scale
		write_byte(200); // brightness
		message_end();
		
		static count[33];
		if (++count[id] >= 3)
		{
			message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
			write_byte(TE_SMOKE); // TE id
			write_coord_f(origin[0]); // x
			write_coord_f(origin[1]); // y
			write_coord_f(origin[2] + 16.0); // z
			write_short(g_sprSteam); // sprite
			write_byte(random_num(15, 20)); // scale
			write_byte(10); // framerate
			message_end();
			
			count[id] = 0;
		}
		
		new attacker = g_burnAttacker[id];
		if (attacker == 0)
			attacker = id;

		new Float:health;
		pev(id, pev_health, health);
		
		if (health < FIREBOMB_DAMAGE)
		{
			ExecuteHamB(Ham_Killed, id, attacker, 0);
		}
		else
		{
			set_pev(id, pev_health, health - FIREBOMB_DAMAGE);
			sendDamage(id, 0, floatround(FIREBOMB_DAMAGE), DMG_BURN, origin);
		}
		
		lastUpdateTime[id] = currentTime;
	}
}

FireBomb::Killed(id)
{
	resetPlayerBurning(id, true);
}

FireBomb::Humanize_Post(id)
{
	resetPlayerBurning(id, true);
}

FireBomb::Disconnect(id)
{
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (g_burnAttacker[i] == id)
			g_burnAttacker[i] = 0;
	}
	
	resetPlayerBurning(id);
}

stock fireBombExplode(ent)
{
	fireBlastEffects(ent);
	
	emit_sound(ent, CHAN_WEAPON, SOUND_FIREBOMB_EXPLODE, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	new Float:origin[3];
	pev(ent, pev_origin, origin);
	
	new Float:radiusRatio, Float:burnDuration, Float:burnUntil;

	new attacker = pev(ent, pev_owner);
	new player = FM_NULLENT;
	
	while ((player = find_ent_in_sphere(player, origin, FIREBOMB_RADIUS)) != 0)
	{
		if (!is_user_alive(player) || !isZombie(player))
			continue;
		
		radiusRatio = 1.0 - entity_range(ent, player) / FIREBOMB_RADIUS;
		burnDuration = floatmax(FIREBOMB_DURATION_MIN * radiusRatio, FIREBOMB_DURATION_MAX);
		
		g_isBurning[player] = true;
		g_burnAttacker[player] = attacker;
		
		burnUntil = get_gametime() + burnDuration;
		if (burnUntil > g_burnStart[player] + g_burnDuration[player])
		{
			g_burnStart[player] = get_gametime();
			g_burnDuration[player] = burnDuration;
		}
	}
	
	remove_entity(ent);
}

stock fireBlastEffects(ent)
{
	new Float:origin[3];
	pev(ent, pev_origin, origin);
	
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_BEAMCYLINDER); // TE id
	write_coord_f(origin[0]); // x
	write_coord_f(origin[1]); // y
	write_coord_f(origin[2] + 16.0); // z
	write_coord_f(origin[0]); // x axis
	write_coord_f(origin[1]); // y axis
	write_coord_f(origin[2] + 250.0); // z axis
	write_short(g_sprShockwave); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(5); // life
	write_byte(25); // width
	write_byte(0); // noise
	write_byte(200); // red
	write_byte(50); // green
	write_byte(0); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();
	
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_BEAMCYLINDER); // TE id
	write_coord_f(origin[0]); // x
	write_coord_f(origin[1]); // y
	write_coord_f(origin[2] + 16.0); // z
	write_coord_f(origin[0]); // x axis
	write_coord_f(origin[1]); // y axis
	write_coord_f(origin[2] + 400.0); // z axis
	write_short(g_sprShockwave); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(5); // life
	write_byte(25); // width
	write_byte(0); // noise
	write_byte(200); // red
	write_byte(50); // green
	write_byte(0); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();
	
	// Dynamic light
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_DLIGHT);
	write_coord_f(origin[0]); // position.x
	write_coord_f(origin[1]); // position.y
	write_coord_f(origin[2]); // position.z
	write_byte(30); // radius in 10's
	write_byte(200); // red
	write_byte(50); // green
	write_byte(0); // blue
	write_byte(6); // life in 0.1's
	write_byte(40) // decay rate in 0.1's
	message_end();
}

stock resetPlayerBurning(id, bool:effects=false)
{
	if (!g_isBurning[id])
		return;
	
	g_isBurning[id] = false;
	g_burnDuration[id] = 0.0;
	g_burnAttacker[id] = 0;

	if (effects)
	{
		new Float:origin[3];
		pev(id, pev_origin, origin);
		
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_SMOKE); // TE id
		write_coord_f(origin[0]); // x
		write_coord_f(origin[1]); // y
		write_coord_f(origin[2] + 16.0); // z
		write_short(g_sprSteam); // sprite
		write_byte(random_num(15, 20)); // scale
		write_byte(10); // framerate
		message_end();
	}
}