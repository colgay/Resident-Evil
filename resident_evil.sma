#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <orpheu>
#include <orpheu_stocks>
#include <gamedata_stocks>
#include <nvault>

#define VERSION "0.1"

#include "zombiemod/consts.sma"
#include "zombiemod/vars.sma"
#include "zombiemod/hooks.sma"

#include "zombiemod/player.sma"

#include "zombiemod/human/human.sma"
#include "zombiemod/human/leader.sma"

#include "zombiemod/zombie/zombie.sma"
#include "zombiemod/zombie/nemesis.sma"
#include "zombiemod/zombie/gmonster.sma"
#include "zombiemod/zombie/zombie_fast.sma"
#include "zombiemod/zombie/zombie_light.sma"
#include "zombiemod/zombie/zombie_heavy.sma"

#include "zombiemod/gamerules.sma"

#include "zombiemod/grenade/firebomb.sma"
#include "zombiemod/grenade/icebomb.sma"
#include "zombiemod/grenade/flare.sma"
#include "zombiemod/grenade/virusbomb.sma"

#include "zombiemod/buy/buy.sma"

#include "zombiemod/hudinfo.sma"

#include "zombiemod/ammo.sma"
#include "zombiemod/menu.sma"
#include "zombiemod/misc.sma"

#include "zombiemod/stocks.sma"

public plugin_precache()
{
	OnPluginPrecache();
}

public plugin_init()
{
	register_plugin("TiG Zombie Mod", VERSION, "penguinux");
	
	OnPluginInit();
}

public plugin_natives()
{
	OnPluginNatives();
}

public plugin_end()
{
	OnPluginEnd();
}

public client_disconnected(id)
{
	OnClientDisconnect(id);
}

public client_putinserver(id)
{
	OnClientPutInServer(id);
}