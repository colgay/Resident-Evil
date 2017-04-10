Menu::Init()
{
	register_clcmd("chooseteam", "CmdChooseTeam");
	register_clcmd("jointeam", "CmdChooseTeam");
}

public CmdChooseTeam(id)
{
	if (is_user_connected(id) && (1 <= getPlayerData(id, "m_iTeam") <= 2))
	{
		ShowGameMenu(id);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public ShowGameMenu(id)
{
	static text[64];
	formatex(text, charsmax(text), "Resident Evil \r%s", VERSION);
	
	new menu = menu_create(text, "HandleGameMenu");
	
	menu_additem(menu, "What's new?");
	menu_additem(menu, "Buy");
	menu_additem(menu, "Choose zombie type");
	menu_additem(menu, "Choose your weapons");

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\\y");
	menu_display(id, menu);
}

public HandleGameMenu(id, menu, item)
{
	menu_destroy(menu);
	
	if (menu == MENU_EXIT)
		return;
	
	switch (item)
	{
		case 0: client_print(id, print_chat, "nothing new");
		case 1: ShowBuyMenu(id);
		case 2: ShowZombieTypeMenu(id);
		case 3:
		{
			CmdChooseWeapons(id);
		}
	}
}