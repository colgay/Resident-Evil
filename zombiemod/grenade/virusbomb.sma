const NADE_VIRUSBOMB  = 7203;
const NADE_VIRUSBOMB2 = 6192;

const Float:VIURSBOMB_RADIUS = 240.0

new const Float:VIURSBOMB_DAMAGE[] = {100.0, 200.0};
new const Float:VIURSBOMB_ADD_HP_RATIO[] = {1.5, 2.5};
new const Float:VIURSBOMB_MAX_ADD_HP[] = {1500.0, 2500.0};

new const VIRUSBOMB_VIEW_MODEL[] = "models/resident_evil/v_virus_bomb.mdl";

VirusBomb::Precache()
{
	precache_model(VIRUSBOMB_VIEW_MODEL);
	precache_sound("player/bhit_helmet-1.wav");
}

VirusBomb::Init()
{
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "VirusBomb@Deploy", 1);
}

VirusBomb::SetModel(ent, const model[])
{
	if (equal(model[7], "w_hegrenade.mdl"))
	{
		new Float:dmgTime;
		pev(ent, pev_dmgtime, dmgTime);
		
		if (dmgTime == 0.0)
			return;
		
		new owner = pev(ent, pev_owner);
		if (!is_user_connected(owner) || !isZombie(owner))
			return;
		
		if (getGmonster(owner))
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BEAMFOLLOW);
			write_short(ent); // entity
			write_short(g_sprTrail) // sprite
			write_byte(10) // life
			write_byte(10) // width
			write_byte(200) // r
			write_byte(0) // g
			write_byte(200) // b
			write_byte(200) // brightness
			message_end()
			
			set_rendering(ent, kRenderFxGlowShell, 200, 0, 200, kRenderNormal, 16);
			
			set_pev(ent, PEV_NADE_TYPE, NADE_VIRUSBOMB2);
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
			write_byte(200) // g
			write_byte(0) // b
			write_byte(200) // brightness
			message_end()
			
			set_rendering(ent, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16);
			
			set_pev(ent, PEV_NADE_TYPE, NADE_VIRUSBOMB);
		}
	}
}

VirusBomb::GrenadeThink(ent)
{
	if (!pev_valid(ent))
		HOOK_RETURN(HAM_IGNORED);
	
	if (pev(ent, PEV_NADE_TYPE) == NADE_VIRUSBOMB || pev(ent, PEV_NADE_TYPE) == NADE_VIRUSBOMB2)
	{
		new Float:dmgTime;
		pev(ent, pev_dmgtime, dmgTime);
		
		if (dmgTime > get_gametime())
			HOOK_RETURN(HAM_IGNORED);
		
		virusBombExplode(ent);
		HOOK_RETURN(HAM_SUPERCEDE);
	}
	
	HOOK_RETURN(HAM_IGNORED);
}

public VirusBomb::Deploy(ent)
{
	if (!pev_valid(ent))
		return;
	
	new id = getPlayerItemDataEnt(ent, "m_pPlayer");
	
	if (is_user_alive(id) && isZombie(id))
	{
		set_pev(id, pev_viewmodel2, VIRUSBOMB_VIEW_MODEL);
	}
}

stock virusBombExplode(ent)
{
	infectionBlastEffect(ent);
	
	new Float:origin[3];
	pev(ent, pev_origin, origin);
	
	new owner = pev(ent, pev_owner);
	new player = FM_NULLENT;

	new Float:ratio;
	new Float:damage, Float:armor, Float:modifier;
	new Float:health, Float:hpRatio, Float:maxAddHp;
	
	while ((player = find_ent_in_sphere(player, origin, VIURSBOMB_RADIUS)) != 0)
	{
		if (!is_user_alive(player))
			continue;
		
		if (!isZombie(player))
		{
			ratio = (1.0 - entity_range(ent, player) / VIURSBOMB_RADIUS);
			
			if (pev(ent, PEV_NADE_TYPE) == NADE_VIRUSBOMB)
				damage = VIURSBOMB_DAMAGE[0];
			else
				damage = VIURSBOMB_DAMAGE[1];

			pev(player, pev_armorvalue, armor);
			if (armor >= damage)
			{
				set_pev(player, pev_armorvalue, armor - damage);
				emit_sound(player, CHAN_VOICE, "player/bhit_helmet-1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
				infectPlayer(player, owner, true);
				set_user_health(player, get_user_health(player) / 2);
			}
			
			sendDamage(player, 0, 1, DMG_ACID, origin);
			
			modifier = 1.0 - ratio;
			if (modifier < getPlayerDataF(player, "m_flVelocityModifier"))
				setPlayerDataF(player, "m_flVelocityModifier", modifier);
		}
		else
		{
			if (pev(ent, PEV_NADE_TYPE) == NADE_VIRUSBOMB)
			{
				hpRatio = VIURSBOMB_ADD_HP_RATIO[0];
				maxAddHp = VIURSBOMB_MAX_ADD_HP[0];
			}
			else
			{
				hpRatio = VIURSBOMB_ADD_HP_RATIO[1];
				maxAddHp = VIURSBOMB_MAX_ADD_HP[1];
			}
			
			pev(player, pev_health, health);
			if (health * hpRatio > health + maxAddHp)
				health += maxAddHp;
			else
				health *= hpRatio;
			
			set_pev(player, pev_health, health);
		}
	}
	
	remove_entity(ent);
}

stock infectionBlastEffect(ent)
{
	new Float:origin[3];
	pev(ent, pev_origin, origin);
	
	new color[3];
	if (pev(ent, PEV_NADE_TYPE) == NADE_VIRUSBOMB)
		color = {0, 200, 0};
	else
		color = {200, 0, 200};

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