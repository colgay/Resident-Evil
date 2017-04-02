#define Player::%0(%1) 			Player@%0(%1)
#define Human::%0(%1) 			Human@%0(%1)
#define Leader::%0(%1) 			Leader@%0(%1)
#define Zombie::%0(%1) 			Zombie@%0(%1)
#define Nemesis::%0(%1) 		Nemesis@%0(%1)
#define Gmonster::%0(%1) 		Gmonster@%0(%1)
#define FastZombie::%0(%1) 		FastZombie@%0(%1)
#define LightZombie::%0(%1) 	LightZombie@%0(%1)
#define HeavyZombie::%0(%1) 	HeavyZombie@%0(%1)
#define GameRules::%0(%1) 		GameRules@%0(%1)
#define FireBomb::%0(%1) 		FireBomb@%0(%1)
#define IceBomb::%0(%1) 		IceBomb@%0(%1)
#define Flare::%0(%1) 			Flare@%0(%1)
#define VirusBomb::%0(%1) 		VirusBomb@%0(%1)
#define Buy::%0(%1) 			Buy@%0(%1)
#define HudInfo::%0(%1) 		HudInfo@%0(%1)
#define Misc::%0(%1) 			Misc@%0(%1)
#define Menu::%0(%1) 			Menu@%0(%1)

#define HOOK_RESULT _hookResult
#define HOOK_RETURN(%0) return hookReturn(%0)

#define FFADE_IN 		0x0000 // Just here so we don't pass 0 into the function
#define FFADE_OUT 		0x0001 // Fade out (not in)
#define FFADE_MODULATE 	0x0002 // Modulate (don't blend)
#define FFADE_STAYOUT 	0x0004 // ignores the duration, stays faded out until new ScreenFade message received

#define ZCLASS_SPECIAL -2
#define ZCLASS_BOSS -3

#define PEV_NADE_TYPE pev_flTimeStepSound

enum
{
	TEAM_UNASSIGNED,
	TEAM_TERRORIST,
	TEAM_CT,
	TEAM_SPECTATOR
};

enum
{
	KNIFE_IDLE,
	KNIFE_ATTACK1HIT,
	KNIFE_ATTACK2HIT,
	KNIFE_DRAW,
	KNIFE_STABHIT,
	KNIFE_STABMISS,
	KNIFE_MIDATTACK1HIT,
	KNIFE_MIDATTACK2HIT
};

enum
{
	Event_Target_Bombed = 1,
	Event_VIP_Escaped,
	Event_VIP_Assassinated,
	Event_Terrorists_Escaped,
	Event_CTs_PreventEscape,
	Event_Escaping_Terrorists_Neutralized,
	Event_Bomb_Defused,
	Event_CTs_Win,
	Event_Terrorists_Win,
	Event_Round_Draw,
	Event_All_Hostages_Rescued,
	Event_Target_Saved,
	Event_Hostages_Not_Rescued,
	Event_Terrorists_Not_Escaped,
	Event_VIP_Not_Escaped,
	Event_Game_Commencing,
};

enum
{
	WinStatus_CT = 1,
	WinStatus_Terrorist,
	WinStatus_Draw
};

enum(+=50)
{
	TASK_ROUNDSTART = 0,
	TASK_RESPAWN,
	TASK_FROZEN,
	TASK_HUDINFO
};

enum
{
	NEMESIS_1ST = 1,
	NEMESIS_2ND
};

enum
{
	GMONSTER_1ST = 1,
	GMONSTER_2ND,
	GMONSTER_3RD
};

enum
{
	LEADER_MALE = 1,
	LEADER_FEMALE,
};

enum
{
	POISON_T_VIRUS = 1,
	POISON_N_VIRUS,
	POISON_G_VIRUS
};

new const SOUND_WARNING[] = "resident_evil/warning.wav";

new const Float:WEAPON_KNOCKBACK[] = 
{
	0.0, 
	40.0, //p228 
	0.0, 
	200.0, //scout
	0.0, //hegrenade
	80.0, //xm1014
	0.0, //c4
	37.0, //mac10
	65.0, //aug
	0.0, //smoke
	35.0, //elite
	37.5, //fiveseven
	40.0, //ump45
	67.7, //sg550
	44.0, //galil
	45.0, //famas
	40.0, //usp
	35.0, //glock18
	300.0, //awp
	42.5, //mp5
	60.0, //m249
	90.0, //m3
	57.5, //m4a1
	36.0, //tmp
	70.0, //g3sg1
	0.0, //flash
	100.0, //deagle
	62.5, //sg552
	60.0, //ak47
	1.0, //knife
	40.0 //p90
};

new const Float:WEAPON_PAINSHOCK[] = 
{
	0.0, 
	0.85, //p228 
	0.0, 
	0.6, //scout
	0.0, //hegrenade
	0.65,//xm1014
	0.0,//c4
	0.9,//mac10
	0.7,//aug
	0.0,//smoke
	0.9,//elite
	0.88,//fiveseven
	0.84,//ump45
	0.675,//sg550
	0.84,//galil
	0.825,//famas
	0.84,//usp
	0.92,//glock18
	0.5,//awp
	0.85,//mp5
	0.7,//m249
	0.6,//m3
	0.75,//m4a1
	0.9,//tmp
	0.65,//g3sg1
	0.0,//flash
	0.1,//deagle
	0.7,//sg552
	0.725,//ak47
	0.8,//knife
	0.875//p90
}