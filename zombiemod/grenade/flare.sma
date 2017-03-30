const NADE_FLARE = 3425;

Flare::Precache()
{
	precache_sound("items/nvg_on.wav");
}

Flare::SetModel(ent, const model[])
{
	if (equal(model[7], "w_smokegrenade.mdl"))
	{
		new Float:dmgTime;
		pev(ent, pev_dmgtime, dmgTime);
		
		if (dmgTime == 0.0)
			return;
		
		new owner = pev(ent, pev_owner);
		if (isZombie(owner))
			return;
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(ent); // entity
		write_short(g_sprTrail) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(50); // r
		write_byte(50); // g
		write_byte(150); // b
		write_byte(200) // brightness
		message_end()
		
		set_rendering(ent, kRenderFxGlowShell, 50, 50, 150, kRenderNormal, 16);
		
		set_pev(ent, PEV_NADE_TYPE, NADE_FLARE);
	}
}

Flare::GrenadeThink(ent)
{
	if (!pev_valid(ent))
		HOOK_RETURN(HAM_IGNORED);
	
	if (pev(ent, PEV_NADE_TYPE) == NADE_FLARE)
	{
		new Float:currentTime = get_gametime();
		
		new Float:dmgTime;
		pev(ent, pev_dmgtime, dmgTime);
		
		if (dmgTime > currentTime)
			HOOK_RETURN(HAM_IGNORED);
		
		if (pev(ent, pev_bInDuck) == 1)
		{
			new Float:startTime;
			pev(ent, pev_fuser1, startTime);
			
			if (currentTime >= startTime + 60.0)
			{
				remove_entity(ent);
				HOOK_RETURN(HAM_SUPERCEDE);
			}

			new Float:origin[3];
			pev(ent, pev_origin, origin);
	
			message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
			write_byte(TE_DLIGHT); // TE id
			write_coord_f(origin[0]); // x
			write_coord_f(origin[1]); // y
			write_coord_f(origin[2]); // z
			write_byte(30); // radius
			write_byte(25); // r
			write_byte(25); // g
			write_byte(100); // b
			write_byte(31); //life
			write_byte(1); //decay rate
			message_end();

			message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
			write_byte(TE_SPARKS) // TE id
			write_coord_f(origin[0]) // x
			write_coord_f(origin[1]) // y
			write_coord_f(origin[2]) // z
			message_end()

			set_pev(ent, pev_dmgtime, currentTime + 3.0);
		}
		else if ((pev(ent, pev_flags) & FL_ONGROUND) && getEntSpeed(ent) < 10)
		{
			emit_sound(ent, CHAN_WEAPON, "items/nvg_on.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			
			set_pev(ent, pev_bInDuck, 1);
			set_pev(ent, pev_fuser1, currentTime);
			set_pev(ent, pev_dmgtime, currentTime + 0.1);
		}
		else
		{
			set_pev(ent, pev_dmgtime, currentTime + 0.1);
		}
	}
	
	HOOK_RETURN(HAM_IGNORED);
}