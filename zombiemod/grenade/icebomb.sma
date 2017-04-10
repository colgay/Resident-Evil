const NADE_ICEBOMB = 8234;
const NADE_ICEBOMB2 = 7927;

const Float:ICEBOMB_RADIUS = 240.0;

new const Float:ICEBOMB_DURATION_MIN[] = {2.5, 4.0};
new const Float:ICEBOMB_DURATION_MAX[] = {4.0, 6.0};

new const SOUND_ICEBOMB_EXPLODE[] = "resident_evil/weapons/frostnova.wav";
new const SOUND_ICEBOMB_FREEZE[] = "resident_evil/weapons/impalehit.wav";
new const SOUND_ICEBOMB_UNFREEZE[] = "resident_evil/weapons/impalelaunch1.wav";

new bool:g_isFrozen[33];
new Float:g_frozenStart[33];
new Float:g_frozenDuration[33];

IceBomb::Precache()
{
	precache_sound(SOUND_ICEBOMB_EXPLODE);
	precache_sound(SOUND_ICEBOMB_FREEZE);
	precache_sound(SOUND_ICEBOMB_UNFREEZE);
}

IceBomb::SetModel(ent, const model[])
{
	if (equal(model[7], "w_flashbang.mdl"))
	{
		new Float:dmgTime;
		pev(ent, pev_dmgtime, dmgTime);
		
		if (dmgTime == 0.0)
			return;
		
		new owner = pev(ent, pev_owner);
		if (isZombie(owner))
			return;
		
		if (getLeader(owner))
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BEAMFOLLOW);
			write_short(ent); // entity
			write_short(g_sprTrail) // sprite
			write_byte(10) // life
			write_byte(10) // width
			write_byte(50) // r
			write_byte(150) // g
			write_byte(255) // b
			write_byte(200) // brightness
			message_end()
			
			set_rendering(ent, kRenderFxGlowShell, 50, 150, 255, kRenderNormal, 16);
			
			set_pev(ent, PEV_NADE_TYPE, NADE_ICEBOMB2);
		}
		else
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BEAMFOLLOW);
			write_short(ent); // entity
			write_short(g_sprTrail) // sprite
			write_byte(10) // life
			write_byte(10) // width
			write_byte(0) // r
			write_byte(75) // g
			write_byte(150) // b
			write_byte(200) // brightness
			message_end()
			
			set_rendering(ent, kRenderFxGlowShell, 0, 75, 150, kRenderNormal, 16);
			
			set_pev(ent, PEV_NADE_TYPE, NADE_ICEBOMB);
		}
	}
}

IceBomb::GrenadeThink(ent)
{
	if (!pev_valid(ent))
		HOOK_RETURN(HAM_IGNORED);
	
	if (pev(ent, PEV_NADE_TYPE) == NADE_ICEBOMB || pev(ent, PEV_NADE_TYPE) == NADE_ICEBOMB2)
	{
		new Float:dmgTime;
		pev(ent, pev_dmgtime, dmgTime);
		
		if (dmgTime > get_gametime())
			HOOK_RETURN(HAM_IGNORED);
		
		iceBombExplode(ent);
		HOOK_RETURN(HAM_SUPERCEDE);
	}
	
	HOOK_RETURN(HAM_IGNORED);
}

IceBomb::ResetMaxSpeed_Post(id)
{
	if (g_isFrozen[id] && isZombie(id))
	{
		set_user_maxspeed(id, 1.0);
	}
}

IceBomb::PlayerJump(id)
{
	if (g_isFrozen[id] && isZombie(id))
	{
		new oldButtons = pev(id, pev_oldbuttons);
		if(~oldButtons & IN_JUMP)
			set_pev(id, pev_oldbuttons, oldButtons | IN_JUMP)
	}
}

IceBomb::PlayerDuck(id)
{
	if (g_isFrozen[id] && isZombie(id))
	{
		new oldButtons = pev(id, pev_oldbuttons);
		if(~oldButtons & IN_DUCK)
			set_pev(id, pev_oldbuttons, oldButtons | IN_DUCK)
	}
}

IceBomb::Killed(id)
{
	removeFrozen(id, true);
}

IceBomb::Humanize_Post(id)
{
	removeFrozen(id, true);
}

IceBomb::Disconnect(id)
{
	removeFrozen(id);
}

public TaskRemoveFrozen(taskid)
{
	new id = taskid - TASK_FROZEN;
	removeFrozen(id, true);
}

stock iceBombExplode(ent)
{
	iceBlastEffects(ent);
	
	emit_sound(ent, CHAN_WEAPON, SOUND_ICEBOMB_EXPLODE, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	new Float:origin[3];
	pev(ent, pev_origin, origin);

	new player = FM_NULLENT;
	
	new Float:radiusRatio, Float:duration;

	while ((player = find_ent_in_sphere(player, origin, ICEBOMB_RADIUS)) != 0)
	{
		if (!is_user_alive(player) || !isZombie(player))
			continue;
		
		radiusRatio = 1.0 - (entity_range(ent, player) / ICEBOMB_RADIUS);
		
		if (pev(ent, PEV_NADE_TYPE) == NADE_ICEBOMB)
		{
			duration = floatmax(ICEBOMB_DURATION_MAX[0] * radiusRatio, ICEBOMB_DURATION_MIN[0]);
			
			if (getNemesis(player) || getGmonster(player) > GMONSTER_1ST)
				duration = 0.0;
		}
		else
			duration = floatmax(ICEBOMB_DURATION_MAX[1] * radiusRatio, ICEBOMB_DURATION_MIN[1]);
		
		if (get_gametime() + duration > g_frozenStart[player] + g_frozenDuration[player])
			frozenPlayer(player, duration);
	}
	
	remove_entity(ent);
}

stock iceBlastEffects(ent)
{
	new Float:origin[3];
	pev(ent, pev_origin, origin);
	
	new color[3];
	if (pev(ent, PEV_NADE_TYPE) == NADE_ICEBOMB)
		color = {0, 75, 150};
	else
		color = {50, 150, 255};
	
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
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
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
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
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
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(6); // life in 0.1's
	write_byte(40) // decay rate in 0.1's
	message_end();
}

stock frozenPlayer(id, Float:duration)
{
	g_isFrozen[id] = true;
	g_frozenStart[id] = get_gametime();
	g_frozenDuration[id] = duration;
	
	resetPlayerMaxSpeed(id);

	emit_sound(id, CHAN_BODY, SOUND_ICEBOMB_FREEZE, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	sendScreenFade(id, 1.0, duration, FFADE_IN, {0, 100, 200}, 120, true);
	sendDamage(id, 0, 0, DMG_DROWN, Float:{0.0, 0.0, 0.0});
	
	set_user_rendering(id, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 16);
	
	set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
	
	remove_task(id + TASK_FROZEN);
	set_task(duration, "TaskRemoveFrozen", id + TASK_FROZEN);
	
	//emit_sound(id, CHAN_BODY, SOUND_FROZEN, 1.0, ATTN_NORM, 0, PITCH_NORM);
}

stock removeFrozen(id, bool:effect=false)
{
	if (!g_isFrozen[id])
		return;
	
	remove_task(id + TASK_FROZEN);
	
	g_isFrozen[id] = false;
	g_frozenDuration[id] = 0.0;
	
	if (effect)
	{
		resetPlayerMaxSpeed(id);
		set_user_rendering(id);

		new Float:origin[3];
		pev(id, pev_origin, origin);
		
		// Break model
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_BREAKMODEL); // TE id
		write_coord_f(origin[0]); // x
		write_coord_f(origin[1]); // y
		write_coord_f(origin[2] + 24.0); // z
		write_coord(10); // size x
		write_coord(10); // size y
		write_coord(10); // size z
		write_coord(random_num(-50, 50)); // velocity x
		write_coord(random_num(-50, 50)); // velocity y
		write_coord(25); // velocity z
		write_byte(10); // random velocity
		write_short(g_modelGlass); // model
		write_byte(10); // count
		write_byte(25); // life
		write_byte(0x01); // flags
		message_end();
		
		emit_sound(id, CHAN_BODY, SOUND_ICEBOMB_UNFREEZE, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
}