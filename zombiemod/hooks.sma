new g_fwEntSpawn;

public OnPluginPrecache()
{
	g_fwEntSpawn = register_forward(FM_Spawn, "OnEntSpawn");
	
	Leader::Precache();
	Zombie::Precache();
	Nemesis::Precache();
	Gmonster::Precache();
	FastZombie::Precache();
	LightZombie::Precache();
	HeavyZombie::Precache();
	GameRules::Precache();
	FireBomb::Precache();
	IceBomb::Precache();
	VirusBomb::Precache();
	Flare::Precache();
	Buy::Precache();
	Misc::Precache();
}

public OnPluginInit()
{
	register_event("HLTV", "OnEventNewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "OnEventDeathMsg", "a");

	register_logevent("OnEventRoundStart", 2, "1=Round_Start");
	
	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");
	register_forward(FM_CmdStart, "OnCmdStart");
	register_forward(FM_SetModel, "OnSetModel");
	
	unregister_forward(FM_Spawn, g_fwEntSpawn);
	
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn");
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled");
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", 1);
	RegisterHam(Ham_Player_Jump, "player", "OnPlayerJump");
	RegisterHam(Ham_Player_Duck, "player", "OnPlayerDuck");

	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "OnPlayerResetMaxSpeed_Post", 1);

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "OnKnifeDeploy_Post", 1);

	RegisterHam(Ham_Touch, "weaponbox", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "weapon_shield", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "armoury_entity", "OnWeaponTouch");
	
	RegisterHam(Ham_Think, "grenade", "OnGrenadeThink");
	
	g_maxClients = get_maxplayers();
	
	Player::Init();
	Human::Init();
	Leader::Init();
	Zombie::Init();
	Nemesis::Init();
	Gmonster::Init();
	FastZombie::Init();
	LightZombie::Init();
	HeavyZombie::Init();
	GameRules::Init();
	VirusBomb::Init();
	Buy::Init();
	HudInfo::Init();
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
	Player::NewRound();
}

public OnEventRoundStart()
{
	GameRules::RoundStart();
}

public OnEventDeathMsg()
{
	new killer = read_data(1);
	new victim = read_data(2);
	/*new bool:isHeadshot = bool:read_data(3);
	
	new weaponName[32];
	read_data(4, weaponName, charsmax(weaponName));*/
	
	Player::DeathMsg(killer, victim);
}

public OnClientDisconnect(id)
{
	Player::Disconnect(id);
	Leader::Disconnect(id);
	Zombie::Disconnect(id);
	FireBomb::Disconnect(id);
	IceBomb::Disconnect(id);
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
	FireBomb::Killed(id);
	IceBomb::Killed(id);
}

public OnPlayerKilled_Post(id, attacker, shouldGib)
{
	GameRules::PlayerKilled_Post(id);
	//Player::Killed_Post(id, attacker);
	Leader::Killed_Post(id);
	Zombie::Killed_Post(id);
}

public OnPlayerJump(id)
{
	IceBomb::PlayerJump(id);
}

public OnPlayerDuck(id)
{
	IceBomb::PlayerDuck(id);
}

public OnPlayerResetMaxSpeed_Post(id)
{
	if (!pev_valid(id) || !is_user_alive(id))
		return;
	
	Leader::ResetMaxSpeed(id);
	Nemesis::ResetMaxSpeed_Post(id);
	Gmonster::ResetMaxSpeed_Post(id);
	FastZombie::ResetMaxSpeed_Post(id);
	LightZombie::ResetMaxSpeed_Post(id);
	HeavyZombie::ResetMaxSpeed_Post(id);
	IceBomb::ResetMaxSpeed_Post(id);
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
	Leader::WeaponTouch(weapon, toucher);
	
	return HOOK_RESULT;
}

public OnGrenadeThink(ent)
{
	if (!pev_valid(ent))
		return HAM_IGNORED;
	
	HOOK_RESULT = HAM_IGNORED;
	
	FireBomb::GrenadeThink(ent);
	IceBomb::GrenadeThink(ent);
	Flare::GrenadeThink(ent);
	VirusBomb::GrenadeThink(ent);
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
	FireBomb::PlayerPreThink(id);
}

public OnSetModel(ent, const model[])
{
	if (!pev_valid(ent))
		return;
	
	FireBomb::SetModel(ent, model);
	IceBomb::SetModel(ent, model);
	Flare::SetModel(ent, model);
	VirusBomb::SetModel(ent, model);
}

public OnPlayerInfect(id, attacker)
{
	Nemesis::Infect(id)
	Gmonster::Infect(id)
}

public OnPlayerInfect_Post(id, attacker)
{
	Leader::Infect_Post(id);
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
	Leader::Humanize_Post(id);
	Zombie::Humanize_Post(id);
	GameRules::Humanize_Post(id);
	FireBomb::Humanize_Post(id);
	IceBomb::Humanize_Post(id);
}

public OnHumanArmorDamage(id, attacker, Float:damage, &Float:armorRatio, &Float:armorBonus)
{
	Nemesis::HumanArmorDamage(attacker, armorRatio, armorBonus);
	Gmonster::HumanArmorDamage(attacker, armorRatio, armorBonus);
}

public OnHumanInfection(id, attacker, Float:damage)
{
	HOOK_RESULT = PLUGIN_CONTINUE;
	
	Nemesis::HumanInfection(attacker);
	return HOOK_RESULT;
}

public OnKnifeKnockBack(id, attacker, Float:damage, &Float:power)
{
	
}

public OnKnockBack(id, attacker, Float:damage, &Float:power)
{
	Nemesis::KnockBack(id, power);
	Gmonster::KnockBack(id, power);
	FastZombie::KnockBack(id, power);
	HeavyZombie::KnockBack(id, power);
	LightZombie::KnockBack(id, power);
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

public OnResetHuman(id)
{
	Leader::ResetHuman(id);
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