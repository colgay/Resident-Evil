new const GMONSTER_HP[3]  = {3000, 2750, 3500};
new const GMONSTER_HP2[3] = {1200, 1000, 1400};
new const Float:GMONSTER_GRAVITY[3] = {0.95, 0.9, 0.7};
new const Float:GMONSTER_SPEED[3] = {0.95, 1.05, 1.2};
new const GMONSTER_MODEL[3][] = {"vip", "vip", "vip"};

new const GMONSTER_VIEW_MODEL[3][] = 
{
	"models/v_knife_r.mdl",
	"models/v_knife_r.mdl",
	"models/v_knife_r.mdl"
};

const Float:G1_MUTATION_RATIO = 0.25;
const Float:G2_MUTATION_RATIO = 0.35;

new g_gmonster[33];

Gmonster::Precache()
{
	precache_model("models/v_knife_r.mdl");
}

Gmonster::Init()
{
	register_clcmd("gmonster", "CmdGmonster");
}

Gmonster::PlayerPreThink(id)
{
	if (is_user_alive(id) && isZombie(id))
	{
		if (g_gmonster[id] == GMONSTER_1ST)
		{
			if (get_user_health(id) <= pev(id, pev_max_health) * G1_MUTATION_RATIO)
			{
				set_hudmessage(200, 0, 100, -1.0, 0.2, 1, 0.0, 3.0, 1.0, 1.0, 1);
				show_hudmessage(0, "G-2 Detected!");
				
				g_gmonster[id]++;
				infectPlayer(id);
			}
		}
		else if (g_gmonster[id] == GMONSTER_2ND)
		{
			if (get_user_health(id) <= pev(id, pev_max_health) * G2_MUTATION_RATIO)
			{
				set_hudmessage(200, 0, 100, -1.0, 0.2, 1, 0.0, 3.0, 1.0, 1.0, 1);
				show_hudmessage(0, "G-3 Detected!");
				
				g_gmonster[id]++;
				infectPlayer(id);
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
	}
}

Gmonster::ResetZombie(id)
{
	g_gmonster[id] = false;
}

Gmonster::Infect_Post(id)
{
	if (g_gmonster[id])
	{
		new g = g_gmonster[id]-1;

		resetZombie(id);
		
		setZombie(id, true);
		g_gmonster[id] = g + 1;
		
		set_user_health(id, GMONSTER_HP[g] + (countHumans() * GMONSTER_HP2[g]));
		set_pev(id, pev_max_health, float(get_user_health(id)));
		
		set_user_gravity(id, GMONSTER_GRAVITY[g]);
		resetPlayerMaxSpeed(id);

		cs_set_user_model(id, GMONSTER_MODEL[g]);
		
		setZombieType(id, ZCLASS_BOSS);
		
		if (g_gmonster[id] > GMONSTER_1ST)
			give_item(id, "weapon_hegrenade");
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

public CmdGmonster(id)
{
	g_gmonster[id] = GMONSTER_1ST;
	infectPlayer(id);
}

stock getGmonster(id)
{
	return g_gmonster[id];
}