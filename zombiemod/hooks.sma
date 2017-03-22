new g_fwEntSpawn;

public OnPluginPrecache()
{
	g_fwEntSpawn = register_forward(FM_Spawn, "OnEntSpawn");
	
	Zombie::Precache();
	Nemesis::Precache();
	Gmonster::Precache();
	FastZombie::Precache();
	LightZombie::Precache();
	HeavyZombie::Precache();
	GameRules::Precache();
	Buy::Precache();
	Misc::Precache();
}

public OnPluginInit()
{
	register_event("HLTV", "OnEventNewRound", "a", "1=0", "2=0");
	
	register_logevent("OnEventRoundStart", 2, "1=Round_Start");
	
	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");
	register_forward(FM_CmdStart, "OnCmdStart");
	
	unregister_forward(FM_Spawn, g_fwEntSpawn);
	
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn");
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled");
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", 1);

	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "OnPlayerResetMaxSpeed_Post", 1);

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "OnKnifeDeploy_Post", 1);

	RegisterHam(Ham_Touch, "weaponbox", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "weapon_shield", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "armoury_entity", "OnWeaponTouch");
	
	g_maxClients = get_maxplayers();
	
	Player::Init();
	Human::Init();
	Zombie::Init();
	Nemesis::Init();
	Gmonster::Init();
	FastZombie::Init();
	LightZombie::Init();
	HeavyZombie::Init();
	GameRules::Init();
	Buy::Init();
}

public OnPluginNatives()
{
}

public OnPluginEnd()
{
}

public OnEntSpawn(ent)
{
	HOOK_RESULT = FMRES_IGNORED;
	GameRules::EntSpawn(ent);
	
	return HOOK_RESULT;
}

public OnEventNewRound()
{
	Nemesis::NewRound();
	GameRules::NewRound();
}

public OnEventRoundStart()
{
	GameRules::RoundStart();
}

public OnClientDisconnect(id)
{
	Player::Disconnect(id);
	Zombie::Disconnect(id);
}

public OnClientPutInServer(id)
{
}

public OnPlayerSpawn(id)
{
	if (!pev_valid(id))
		return;
	
	GameRules::PlayerSpawn(id);
}

public OnPlayerSpawn_Post(id)
{
	if (!pev_valid(id))
		return;
	
	GameRules::PlayerSpawn_Post(id);
}

public OnPlayerKilled(id, attacker, shouldGib)
{
	Zombie::Killed(id);
}

public OnPlayerKilled_Post(id, attacker, shouldGib)
{
	GameRules::PlayerKilled_Post(id);
	Zombie::Killed_Post(id);
}

public OnPlayerResetMaxSpeed_Post(id)
{
	if (!pev_valid(id) || !is_user_alive(id))
		return;
	
	Nemesis::ResetMaxSpeed_Post(id);
	Gmonster::ResetMaxSpeed_Post(id);
	FastZombie::ResetMaxSpeed_Post(id);
	LightZombie::ResetMaxSpeed_Post(id);
	HeavyZombie::ResetMaxSpeed_Post(id);
}

public OnKnifeDeploy_Post(ent)
{
	if (!pev_valid(ent))
		return;
	
	new player = getPlayerItemDataEnt(ent, "m_pPlayer");
	
	if (is_user_alive(player))
	{
		Zombie::KnifeDeploy_Post(player);
	}
}

public OnWeaponTouch(weapon, toucher)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	HOOK_RESULT = HAM_IGNORED;
	Zombie::TouchWeapon(toucher);
	
	return HOOK_RESULT;
}

public OnCmdStart(id, uc)
{
	Nemesis::CmdStart(id, uc);
}

public OnPlayerPreThink(id)
{
	Zombie::PlayerPreThink(id);
	Nemesis::PlayerPreThink(id);
	Gmonster::PlayerPreThink(id);
}

public OnPlayerInfect(id, attacker)
{
}

public OnPlayerInfect_Post(id, attacker)
{
	Zombie::Infect_Post(id);
	Nemesis::Infect_Post(id);
	Gmonster::Infect_Post(id);
	FastZombie::Infect_Post(id);
	LightZombie::Infect_Post(id);
	HeavyZombie::Infect_Post(id);
	GameRules::Infect_Post(id);
}

public OnPlayerHumanize(id)
{
}

public OnPlayerHumanize_Post(id)
{
	Human::Humanize_Post(id);
	Zombie::Humanize_Post(id);
	GameRules::Humanize_Post(id);
}

public OnHumanArmorDamage(id, attacker, Float:damage, &Float:armorRatio, &Float:armorBouns)
{
	Nemesis::HumanArmorDamage(attacker, armorRatio, armorBouns);
}

public OnHumanInfection(id, attacker, Float:damage)
{
	HOOK_RESULT = PLUGIN_CONTINUE;
	
	Nemesis::HumanInfection(attacker);
	return HOOK_RESULT;
}

public OnAddPoison(id, attacker, Float:damage)
{
	HOOK_RESULT = PLUGIN_CONTINUE;

	Nemesis::AddPoison(id, attacker, damage);
	Gmonster::AddPoison(id, attacker, damage);
	return HOOK_RESULT;
}

public OnSetZombieKnifeModel(id)
{
	Zombie::SetKnifeModel(id);
	Nemesis::SetKnifeModel(id);
	Gmonster::SetKnifeModel(id);
	FastZombie::SetKnifeModel(id);
	LightZombie::SetKnifeModel(id);
	HeavyZombie::SetKnifeModel(id);
}

public OnResetZombie(id)
{
	Nemesis::ResetZombie(id);
	Gmonster::ResetZombie(id);
}

public OnBuyItem(id, item)
{
	HOOK_RESULT = PLUGIN_CONTINUE;
	Buy::BuyItem(id, item);
	
	return HOOK_RESULT;
}

public OnBuyItem_Post(id, item)
{
	Buy::BuyItem_Post(id, item);
}

stock hookReturn(any:result)
{
	if (result > HOOK_RESULT)
		HOOK_RESULT = result;
	
	return HOOK_RESULT;
}