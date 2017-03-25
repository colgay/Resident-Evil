#define Player::%0(%1) 			Player@%0(%1)
#define Human::%0(%1) 			Human@%0(%1)
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
#define Buy::%0(%1) 			Buy@%0(%1)
#define Misc::%0(%1) 			Misc@%0(%1)

#define HOOK_RESULT _hookResult
#define HOOK_RETURN(%0) return hookReturn(%0)

#define FFADE_IN 		0x0000 // Just here so we don't pass 0 into the function
#define FFADE_OUT 		0x0001 // Fade out (not in)
#define FFADE_MODULATE 	0x0002 // Modulate (don't blend)
#define FFADE_STAYOUT 	0x0004 // ignores the duration, stays faded out until new ScreenFade message received

#define ZCLASS_SPECIAL -1
#define ZCLASS_BOSS -2

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
	POISON_T_VIRUS = 1,
	POISON_N_VIRUS,
	POISON_G_VIRUS
};