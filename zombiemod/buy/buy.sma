enum(<<= 1)
{
	BUY_TEAM_HUMAN = 1,
	BUY_TEAM_LEADER,
	BUY_TEAM_ZOMBIE,
	BUY_TEAM_NEMESIS,
	BUY_TEAM_GMONSTER
};

const BUY_TEAM_HUMANS = BUY_TEAM_HUMAN | BUY_TEAM_LEADER;
const BUY_TEAM_ZOMBIES = BUY_TEAM_ZOMBIE | BUY_TEAM_NEMESIS | BUY_TEAM_GMONSTER;

new const SOUND_MEDKIT[][] = {"items/smallmedkit1.wav", "items/smallmedkit2.wav"};

new const BUY_ITEM_NAME[][] = 
{
	"Infection Bomb", "Antidote",
	"Vaccine 100mL", "Vaccine 300mL", "Medical Kit", "Antitoxin",
	"Incendiary Grenade", "Nitrogen Grenade", "Liquid Nitrogen", "Flare", "Night Vision",
	"M3", "XM1014",
	"MP5", "UMP45", "P90",
	"Galil", "Famas", "M4A1", "SG552", "AUG",
	"G3SG1", "SG550", "AWP",
	"M249"
};

new const BUY_ITEM_DESC[][] = 
{
	"", "Human",
	"+100AP", "+300AP", "+100HP", "脫毒", 
	"BBQ", "硬膠", "強化硬膠", "黃豆", "I can't see shit",
	"", "",
	"", "", "",
	"", "", "", "", "",
	"", "", "",
	""
};

new BUY_ITEM_TEAM[] = 
{
	BUY_TEAM_ZOMBIE, BUY_TEAM_ZOMBIE, // infection-bomb antidote
	BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, // ap100 ap300 hp100, antitoxin
	BUY_TEAM_HUMANS, BUY_TEAM_HUMAN, BUY_TEAM_LEADER, BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, // fire ice superice flare nvg
	BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, // m3 xm1014
	BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, // mp5 ump45 p90
	BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, // galil famas m4a1 sg552 aug
	BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, BUY_TEAM_HUMANS, // g3sg1 sg550 awp
	BUY_TEAM_HUMANS // m249
};

new const BUY_ITEM_COST[][2] = 
{
	{20, 0}, {35, 0}, // infection-bomb antidote
	{3, 1}, {5, 1}, {6, 2}, {8, 3}, // ap100 ap300 hp100 antitoxin
	{6, 5}, {5, 4}, {10, 6}, {3, 3}, {10, 5}, // fire ice superice flare nvg
	{8, 3}, {13, 4}, // m3 xm1014
	{8, 3}, {7, 2}, {10, 3}, // mp5 ump45 p90
	{9, 3}, {8, 3}, {10, 4}, {11, 4}, {11, 4}, // galil famas m4a1 sg552 aug
	{40, 8}, {45, 7}, {12, 4}, // g3sg1 sg550 scout awp
	{20, 4} // m249
};

enum
{
	BUYITEM_VIRUSBOMB,
	BUYITEM_ANTIDOTE,
	BUYITEM_VACCINE1,
	BUYITEM_VACCINE2,
	BUYITEM_MEDKIT,
	BUYITEM_ANTITOXIN,
	BUYITEM_FIRE,
	BUYITEM_ICE,
	BUYITEM_SUPERICE,
	BUYITEM_FLARE,
	BUYITEM_NVG,
	BUYITEM_FIRSTWPN,
	BUYITEM_LASTWPN = BUYITEM_FIRSTWPN + 14,
};

new Array:g_buyItemName;
new Array:g_buyItemDesc;
new Array:g_buyItemTeam;
new Array:g_buyItemCost;
new Array:g_buyItemRS;
new g_buyItemCount;

Buy::Precache()
{
	g_buyItemName = ArrayCreate(32);
	g_buyItemDesc = ArrayCreate(32);
	g_buyItemTeam = ArrayCreate(1);
	g_buyItemCost = ArrayCreate(1);
	g_buyItemRS = ArrayCreate(1);
	
	for (new i = 0; i < sizeof SOUND_MEDKIT; i++)
	{
		precache_sound(SOUND_MEDKIT[i]);
	}
	
	precache_sound("items/9mmclip1.wav");
}

Buy::Init()
{
	register_clcmd("buy2", "CmdBuy2");

	register_clcmd("buyammo1", "CmdBuyAmmo1");
	register_clcmd("buyammo2", "CmdBuyAmmo2");
	
	for (new i = 0; i < sizeof BUY_ITEM_NAME; i++)
	{
		registerBuyItem(BUY_ITEM_NAME[i], BUY_ITEM_DESC[i], BUY_ITEM_TEAM[i], BUY_ITEM_COST[i][0], BUY_ITEM_COST[i][1]);
	}
}

Buy::BuyItem(id, item)
{
	switch (item)
	{
		case BUYITEM_VIRUSBOMB:
		{
			if (user_has_weapon(id, CSW_HEGRENADE))
			{
				client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				HOOK_RETURN(PLUGIN_HANDLED);
			}
		}
		case BUYITEM_VACCINE1:
		{
			new Float:armor, Float:maxArmor;
			pev(id, pev_armorvalue, armor);
			maxArmor = getMaxArmor(id);
			
			if (armor >= maxArmor)
			{
				client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				HOOK_RETURN(PLUGIN_HANDLED);
			}
		}
		case BUYITEM_VACCINE2:
		{
			new Float:armor, Float:maxArmor;
			pev(id, pev_armorvalue, armor);
			maxArmor = getMaxArmor(id);
			
			if (armor >= maxArmor)
			{
				client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				HOOK_RETURN(PLUGIN_HANDLED);
			}
		}
		case BUYITEM_MEDKIT:
		{
			new Float:health, Float:maxHealth;
			pev(id, pev_health, health);
			pev(id, pev_max_health, maxHealth);
			
			if (health >= maxHealth)
			{
				client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
				HOOK_RETURN(PLUGIN_HANDLED);
			}
		}
		case BUYITEM_FIRE:
		{
			if (user_has_weapon(id, CSW_HEGRENADE))
			{
				new ammoId = getWeaponAmmoType(CSW_HEGRENADE);
				if (cs_get_user_bpammo(id, CSW_HEGRENADE) >= getAmmoMax(ammoId))
				{
					client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
					HOOK_RETURN(PLUGIN_HANDLED);
				}
			}
		}
		case BUYITEM_ICE:
		{
			if (user_has_weapon(id, CSW_FLASHBANG))
			{
				new ammoId = getWeaponAmmoType(CSW_FLASHBANG);
				if (cs_get_user_bpammo(id, CSW_FLASHBANG) >= getAmmoMax(ammoId))
				{
					client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
					HOOK_RETURN(PLUGIN_HANDLED);
				}
			}
		}
		case BUYITEM_SUPERICE:
		{
			if (user_has_weapon(id, CSW_FLASHBANG))
			{
				new ammoId = getWeaponAmmoType(CSW_FLASHBANG);
				if (cs_get_user_bpammo(id, CSW_FLASHBANG) >= getAmmoMax(ammoId))
				{
					client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
					HOOK_RETURN(PLUGIN_HANDLED);
				}
			}
		}
		case BUYITEM_FLARE:
		{
			if (user_has_weapon(id, CSW_SMOKEGRENADE))
			{
				new ammoId = getWeaponAmmoType(CSW_SMOKEGRENADE);
				if (cs_get_user_bpammo(id, CSW_SMOKEGRENADE) >= getAmmoMax(ammoId))
				{
					client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
					HOOK_RETURN(PLUGIN_HANDLED);
				}
			}
		}
	}
	
	HOOK_RETURN(PLUGIN_CONTINUE);
}

Buy::BuyItem_Post(id, item)
{
	switch (item)
	{
		case BUYITEM_VIRUSBOMB:
		{
			give_item(id, "weapon_hegrenade");
		}
		case BUYITEM_VACCINE1:
		{
			new Float:armor, Float:maxArmor;
			pev(id, pev_armorvalue, armor);
			maxArmor = getMaxArmor(id);
			
			if (getPoisonType(id) == POISON_T_VIRUS || getPoisonType(id) == POISON_G_VIRUS)
			{
				if (getPoisonLevel(id) - 0.2 <= 0.0)
					resetPoisoning(id);
				else
				{
					client_print(id, print_center, "你中毒太深, 請再買一次疫苗");
					setPoisonLevel(id, getPoisonLevel(id) - 0.2);
				}
			}
			
			set_pev(id, pev_armorvalue, floatmin(armor + 100.0, maxArmor));
			emit_sound(id, CHAN_ITEM, SOUND_MEDKIT[random(sizeof SOUND_MEDKIT)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case BUYITEM_VACCINE2:
		{
			new Float:armor, Float:maxArmor;
			pev(id, pev_armorvalue, armor);
			maxArmor = getMaxArmor(id);

			if (getPoisonType(id) == POISON_T_VIRUS || getPoisonType(id) == POISON_G_VIRUS)
			{
				if (getPoisonLevel(id) - 0.5 <= 0.0)
					resetPoisoning(id);
				else
				{
					client_print(id, print_center, "你中毒太深, 請再買一次疫苗");
					setPoisonLevel(id, getPoisonLevel(id) - 0.5);
				}
			}

			set_pev(id, pev_armorvalue, floatmin(armor + 300.0, maxArmor));
			emit_sound(id, CHAN_ITEM, SOUND_MEDKIT[random(sizeof SOUND_MEDKIT)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case BUYITEM_MEDKIT:
		{
			new Float:health, Float:maxHealth;
			pev(id, pev_health, health);
			pev(id, pev_max_health, maxHealth);
			
			set_pev(id, pev_health, floatmin(health + 100.0, maxHealth));
			emit_sound(id, CHAN_ITEM, SOUND_MEDKIT[random(sizeof SOUND_MEDKIT)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case BUYITEM_ANTITOXIN:
		{
			new Float:armor, Float:maxArmor;
			pev(id, pev_armorvalue, armor);
			maxArmor = getMaxArmor(id);

			new Float:health, Float:maxHealth;
			pev(id, pev_health, health);
			pev(id, pev_max_health, maxHealth);
			
			resetPoisoning(id);

			set_pev(id, pev_health, floatmin(health + 50.0, maxHealth));
			set_pev(id, pev_armorvalue, floatmin(armor + 100.0, maxArmor));
			
			emit_sound(id, CHAN_ITEM, SOUND_MEDKIT[random(sizeof SOUND_MEDKIT)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case BUYITEM_FIRE:
		{
			if (user_has_weapon(id, CSW_HEGRENADE))
			{
				giveWeaponAmmo(id, CSW_HEGRENADE);
				emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
				give_item(id, "weapon_hegrenade");
			}
		}
		case BUYITEM_ICE:
		{
			if (user_has_weapon(id, CSW_FLASHBANG))
			{
				giveWeaponAmmo(id, CSW_FLASHBANG);
				emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
				give_item(id, "weapon_flashbang");
			}
		}
		case BUYITEM_SUPERICE:
		{
			if (user_has_weapon(id, CSW_FLASHBANG))
			{
				giveWeaponAmmo(id, CSW_FLASHBANG);
				emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
				give_item(id, "weapon_flashbang");
			}
		}
		case BUYITEM_FLARE:
		{
			if (user_has_weapon(id, CSW_SMOKEGRENADE))
			{
				giveWeaponAmmo(id, CSW_SMOKEGRENADE);
				emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
				give_item(id, "weapon_smokegrenade");
			}
		}
		case BUYITEM_FIRSTWPN .. BUYITEM_LASTWPN:
		{
			static const weaponClasses[][] = 
			{
				"m3", "xm1014",
				"mp5navy", "ump45", "p90",
				"galil", "famas", "m4a1", "sg552", "aug",
				"g3sg1", "sg550", "awp",
				"m249"
			};
			
			new class[32] = "weapon_";
			new index = item - BUYITEM_FIRSTWPN;
			
			add(class, charsmax(class), weaponClasses[index]);
			dropWeapons(id, 1);
			give_item(id, class);
		}
	}
}

public CmdBuy2(id)
{
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	ShowBuyMenu(id);
	return PLUGIN_HANDLED;
}

public CmdBuyAmmo1(id)
{
	if (isZombie(id) || !is_user_alive(id))
		return PLUGIN_HANDLED;
	
	buyGunAmmo(id, 1);
	return PLUGIN_HANDLED;
}

public CmdBuyAmmo2(id)
{
	if (isZombie(id) || !is_user_alive(id))
		return PLUGIN_HANDLED;
	
	buyGunAmmo(id, 2);
	return PLUGIN_HANDLED;
}

public ShowBuyMenu(id)
{
	static text[80], desc[32], info[4];

	new team, rs;
	
	formatex(text, charsmax(text), "\yBuy Menu \r[%d RS]\R\yPrice", getResourcePoint(id));
	new menu = menu_create(text, "HandleBuyMenu");
	
	for (new i = 0; i < g_buyItemCount; i++)
	{
		team = ArrayGetCell(g_buyItemTeam, i);
		
		if ((getNemesis(id) && !(team & BUY_TEAM_NEMESIS))
		|| (getGmonster(id) && !(team & BUY_TEAM_GMONSTER))
		|| (isZombie(id) && !getNemesis(id) && !getGmonster(id) && !(team & BUY_TEAM_ZOMBIE))
		|| (getLeader(id) && !(team & BUY_TEAM_LEADER))
		|| (!isZombie(id) && !getLeader(id) && !(team & BUY_TEAM_HUMAN)))
			continue;
		
		formatex(text, charsmax(text), "%a", ArrayGetStringHandle(g_buyItemName, i));
		
		ArrayGetString(g_buyItemDesc, i, desc, charsmax(desc));
		if (desc[0])
			format(text, charsmax(text), "%s \d%s", text, desc);
		
		format(text, charsmax(text), "%s\R\y%d.SP", text, ArrayGetCell(g_buyItemCost, i));
		
		rs = ArrayGetCell(g_buyItemRS, i);
		if (rs)
			format(text, charsmax(text), "%s\r%dRS", text, rs);
		
		num_to_str(i, info, charsmax(info));
		menu_additem(menu, text, info);
	}
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y");
	menu_display(id, menu);
}

public HandleBuyMenu(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	static info[4], dummy;
	menu_item_getinfo(menu, item, dummy, info, charsmax(info), _, _, dummy);
	
	new item2 = str_to_num(info);
	
	new team = ArrayGetCell(g_buyItemTeam, item2);
	if ((getNemesis(id) && !(team & BUY_TEAM_NEMESIS))
	|| (getGmonster(id) && !(team & BUY_TEAM_GMONSTER))
	|| (isZombie(id) && !getNemesis(id) && !getGmonster(id) && !(team & BUY_TEAM_ZOMBIE))
	|| (getLeader(id) && !(team & BUY_TEAM_LEADER))
	|| (!isZombie(id) && !getLeader(id) && !(team & BUY_TEAM_HUMAN)))
		return;
	
	new price = ArrayGetCell(g_buyItemCost, item2);
	new sp = getPlayerPoint(id);
	if (sp < price)
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money");
		return;
	}
	
	new rsCost = ArrayGetCell(g_buyItemRS, item2);
	new rs = getResourcePoint(id);
	if (rs < rsCost)
	{
		client_print(id, print_center, "You have not enough resource point.");
		return;
	}
	
	if (OnBuyItem(id, item2) == PLUGIN_HANDLED)
		return;
	
	setPlayerPoint(id, sp - price);
	setResourcePoint(id, rs - rsCost);
	
	OnBuyItem_Post(id, item2);
}


stock buyGunAmmo(id, slot)
{
	new money = getPlayerPoint(id);
	new resource = getResourcePoint(id);
	new boughtAmmo, canBuy;
	
	// find player items
	new weapon = getPlayerDataEnt(id, "m_rgpPlayerItems", slot);
	new ammoId;
	new max, cost, amount;
	new ammoName[32];
	
	while (pev_valid(weapon))
	{
		// each ammo type can only buy once
		ammoId = getWeaponData(weapon, "m_iPrimaryAmmoType");
		if (ammoId > 0 && (~boughtAmmo & (1 << ammoId)))
		{
			// ammo not full
			max = getAmmoMax(ammoId);
			if (getPlayerData(id, "m_rgAmmo", ammoId) < max)
			{
				cost = getAmmoCost(ammoId);
				if (money >= cost && resource >= 1)
				{
					amount = getAmmoAmount(ammoId);
					getAmmoName(ammoId, ammoName, charsmax(ammoName));
					
					if (ExecuteHamB(Ham_GiveAmmo, id, amount, ammoName, max) > -1)
					{
						boughtAmmo |= (1 << ammoId);
						money -= cost;
						resource -= 1;
					}
				}
				canBuy = true;
			}
		}
		
		weapon = getPlayerItemDataEnt(weapon, "m_pNext");
	}
	
	if (boughtAmmo)
	{
		emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		setPlayerPoint(id, money);
		setResourcePoint(id, resource);
	}
	else if (canBuy)
	{
		client_print(id, print_center, "You have not enough SP or RS");
	}
}

stock registerBuyItem(const name[], const desc[], team, price, rs)
{
	ArrayPushString(g_buyItemName, name);
	ArrayPushString(g_buyItemDesc, desc);
	ArrayPushCell(g_buyItemTeam, team);
	ArrayPushCell(g_buyItemCost, price);
	ArrayPushCell(g_buyItemRS, rs);
	g_buyItemCount++;
	
	return g_buyItemCount - 1;
}