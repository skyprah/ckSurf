
public CheckSpawnPoints() 
{
	if(StrEqual(g_szMapPrefix[0],"surf"))
	{
		if (!g_bNoBlock)
			return;
		new ent, ct, t, spawnpoint;
		ct = 0;
		t= 0;	
		ent = -1;	
		while ((ent = FindEntityByClassname(ent, "info_player_terrorist")) != -1)
		{		
			if (t==0)
			{
				GetEntPropVector(ent, Prop_Data, "m_angRotation", g_fSpawnpointAngle); 
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", g_fSpawnpointOrigin);				
			}
			t++;
		}	
		while ((ent = FindEntityByClassname(ent, "info_player_counterterrorist")) != -1)
		{	
			if (ct==0 && t==0)
			{
				GetEntPropVector(ent, Prop_Data, "m_angRotation", g_fSpawnpointAngle); 
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", g_fSpawnpointOrigin);				
			}
			ct++;
		}	
		
		if (t > 0 || ct > 0)
		{
			if (t < 32)
			{
				while (t < 32)
				{
					spawnpoint = CreateEntityByName("info_player_terrorist");
					if (IsValidEntity(spawnpoint) && DispatchSpawn(spawnpoint))
					{
						ActivateEntity(spawnpoint);
						TeleportEntity(spawnpoint, g_fSpawnpointOrigin, g_fSpawnpointAngle, NULL_VECTOR);
						t++;
					}
				}		
			}

			if (ct < 32)
			{
				while (ct < 32)
				{
					spawnpoint = CreateEntityByName("info_player_counterterrorist");
					if (IsValidEntity(spawnpoint) && DispatchSpawn(spawnpoint))
					{
						ActivateEntity(spawnpoint);
						TeleportEntity(spawnpoint, g_fSpawnpointOrigin, g_fSpawnpointAngle, NULL_VECTOR);
						ct++;
					}
				}			
			}
		}
	}
}


public SetTimelimit()
{
	new maptimes;
	new Float:time;

	time = g_fRecordMapTime;
	maptimes = g_MapTimesCount;
	if (maptimes < 50)
	{
		ServerCommand("mp_timelimit 120");
		ServerCommand("mp_roundtime 120");
		ServerCommand("mp_restartgame 1");		
		return;
	}
	if (time <= 180.0)
	{
		ServerCommand("mp_timelimit 30");
		ServerCommand("mp_roundtime 30");
		ServerCommand("mp_restartgame 1");		
		return;	
	}		
	if (time <= 300.0)
	{
		ServerCommand("mp_timelimit 40");
		ServerCommand("mp_roundtime 40");
		ServerCommand("mp_restartgame 1");		
		return;	
	}		
	if (time <= 600.0)
	{
		ServerCommand("mp_timelimit 60");
		ServerCommand("mp_roundtime 60");
		ServerCommand("mp_restartgame 1");		
		return;	
	}	
	if (time <= 1200.0)
	{
		ServerCommand("mp_timelimit 90");
		ServerCommand("mp_roundtime 90");
		ServerCommand("mp_restartgame 1");		
		return;	
	}	
	if (time > 1200.0)
	{
		ServerCommand("mp_timelimit 120");
		ServerCommand("mp_roundtime 120");
		ServerCommand("mp_restartgame 1");	
		return;
	}
}

public Action:CallAdmin_OnDrawOwnReason(client)
{
	g_bClientOwnReason[client] = true;
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
    if(client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
        return true;  
    return false;
}  

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
FormatLanguage(String:language[])
{
	// Format the input language.
	new length = strlen(language);
	
	if (length <= 1)
		return;
	
	// Capitalize first letter.
	language[0] = CharToUpper(language[0]);
	
	// Lower case the rest.
	for (new i = 1; i < length; i++)
	{
		language[i] = CharToLower(language[i]);
	}
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
LoadCookies(client)
{
	decl String:sCookie[4];
	sCookie[0] = '\0';
	g_bLanguageSelected[client] = true;
	GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));	
	if (sCookie[0] != '\0')
		SetClientLanguageByCode(client, sCookie);	
	else
		g_bLanguageSelected[client] = false;
	g_bLoaded[client] = true;
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
SetClientLanguageByCode(client, const String:code[])
{
	/* Set a client's language based on the language code. */
	new iLangID = GetLanguageByCode(code);	
	if (iLangID >= 0)
		SetClientLanguage2(client, iLangID);
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
SetClientLanguage2(client, language)
{
	// Set language.
	SetClientLanguage(client, language);
	
	Call_StartForward(g_OnLangChanged);
	Call_PushCell(client);
	Call_PushCell(language);
	Call_Finish();
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
public LanguageMenu_Handler(Handle:menu, MenuAction:action, client, item)
{
	/* Handle the language selection menu. */
	switch (action)
	{
		case MenuAction_DrawItem:
		{
			// Disable selection for currently used language.
			decl String:sLangID[4];
			GetMenuItem(menu, item, sLangID, sizeof(sLangID));
			
			if (StringToInt(sLangID) == GetClientLanguage(client))
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			decl String:sLangID[4], String:sLanguage[32];
			GetMenuItem(menu, item, sLangID, sizeof(sLangID), _, sLanguage, sizeof(sLanguage));
			
			new iLangID = StringToInt(sLangID);
			SetClientLanguage2(client, iLangID);
			
			if (g_bUseCPrefs)
			{
				decl String:sLangCode[6];
				GetLanguageInfo(iLangID, sLangCode, sizeof(sLangCode));
				SetClientCookie(client, g_hCookie, sLangCode);
			}
			
			PrintToChat(client, "[%cCK%c] Language changed to \"%s\".", MOSSGREEN,WHITE, sLanguage);
		}
	}
	
	return 0;
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
Init_GeoLang()
{
	// Create and cache language selection menu.
	new Handle:hLangArray = CreateArray(32);
	decl String:sLangID[4];
	decl String:sLanguage[128];
	
	new maxLangs = GetLanguageCount();
	for (new i = 0; i < maxLangs; i++)
	{
		GetLanguageInfo(i, _, _, sLanguage, sizeof(sLanguage));
		//if (StrEqual(sLanguage,"german") || StrEqual(sLanguage,"russian") || StrEqual(sLanguage,"schinese") || StrEqual(sLanguage,"english")  || StrEqual(sLanguage,"swedish")  || StrEqual(sLanguage,"french"))
		if (StrEqual(sLanguage,"english"))
		{
			FormatLanguage(sLanguage);
			PushArrayString(hLangArray, sLanguage);
		}
	}
	
	// Sort languages alphabetically.
	SortADTArray(hLangArray, Sort_Ascending, Sort_String);
	
	// Create and cache the menu.
	g_hLangMenu = CreateMenu(LanguageMenu_Handler, MenuAction_DrawItem);
	SetMenuTitle(g_hLangMenu, "Language:");
	SetMenuPagination(g_hLangMenu, MENU_NO_PAGINATION); 
	
	maxLangs = GetArraySize(hLangArray);
	for (new i = 0; i < maxLangs; i++)
	{
		GetArrayString(hLangArray, i, sLanguage, sizeof(sLanguage));
		
		// Get language ID.
		IntToString(GetLanguageByName(sLanguage), sLangID, sizeof(sLangID));
		
		// Add to menu.
		if (StrEqual(sLanguage,"Schinese"))
			Format(sLanguage, 128, "Chinese");	
		AddMenuItem(g_hLangMenu, sLangID, sLanguage);
	}
	
	SetMenuExitButton(g_hLangMenu, true);
	
	CloseHandle(hLangArray);
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
public CookieMenu_GeoLanguage(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	/* Menu when accessed through !settings. */
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			Format(buffer, maxlen, "Language");
		}
		case CookieMenuAction_SelectOption:
		{
			DisplayMenu(g_hLangMenu, client, MENU_TIME_FOREVER);
		}
	}
}

public OnMapVoteStarted()
{
   	for(new client = 1; client <= MAXPLAYERS; client++)
	{
		g_bMenuOpen[client] = true;
		if (g_bClimbersMenuOpen[client])
			g_bClimbersMenuwasOpen[client]=true;
		else
			g_bClimbersMenuwasOpen[client]=false;		
		g_bClimbersMenuOpen[client] = false;
	}
}

public SetSkillGroups()
{
	//Map Points	
	new mapcount;
	if (g_pr_MapCount < 1)
		mapcount = 1;
	else
		mapcount = g_pr_MapCount;

	g_pr_PointUnit = 1;
	new Float: MaxPoints = (float(mapcount) * 700.0) + (float(g_totalBonusCount) * 150.0);
	new g_RankCount = 0;
	
	decl String:sPath[PLATFORM_MAX_PATH], String:sBuffer[32];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/ckSurf/skillgroups.cfg");	
	
	if (FileExists(sPath))
	{
		new Handle:hKeyValues = CreateKeyValues("ckSurf.SkillGroups");
		if(FileToKeyValues(hKeyValues, sPath) && KvGotoFirstSubKey(hKeyValues))
		{
			do
			{
				if (g_RankCount <= 8)
				{
					KvGetString(hKeyValues, "name", g_szSkillGroups[g_RankCount], 32);
					KvGetString(hKeyValues, "percentage", sBuffer,32);
					if (g_RankCount != 0)
						g_pr_rank_Percentage[g_RankCount] = RoundToCeil(MaxPoints * StringToFloat(sBuffer));  
				}
				g_RankCount++;
			}
			while (KvGotoNextKey(hKeyValues));
		}
		if (hKeyValues != INVALID_HANDLE)
			CloseHandle(hKeyValues);
	}
	else
		SetFailState("<ckSurf> addons/sourcemod/configs/ckSurf/skillgroups.cfg not found.");
}

public SetServerTags()
{
	new Handle:CvarHandle;	
	CvarHandle = FindConVar("sv_tags");
	decl String:szServerTags[2048];
	GetConVarString(CvarHandle, szServerTags, 2048);
	if (StrContains(szServerTags,"ckSurf",true) == -1)
	{
		Format(szServerTags, 2048, "%s, ckSurf",szServerTags);
		SetConVarString(CvarHandle, szServerTags);		
	}
	if (StrContains(szServerTags,"ckSurf 1.",true) == -1 && StrContains(szServerTags,"Tickrate",true) == -1)
	{
		Format(szServerTags, 2048, "%s, ckSurf %s, Tickrate %i",szServerTags,VERSION,g_Server_Tickrate);
		SetConVarString(CvarHandle, szServerTags);
	}
	if (CvarHandle != INVALID_HANDLE)
		CloseHandle(CvarHandle);
}

public PrintConsoleInfo(client)
{
	new timeleft;
	GetMapTimeLeft(timeleft);
	new mins, secs;	
	decl String:finalOutput[1024];
	mins = timeleft / 60;
	secs = timeleft % 60;
	Format(finalOutput, 1024, "%d:%02d", mins, secs);
	new Float:fltickrate = 1.0 / GetTickInterval( );
	

	PrintToConsole(client, "-----------------------------------------------------------------------------------------------------------");
	PrintToConsole(client, "This server is running ckSurf v%s - Author: Elzi - Server tickrate: %i", VERSION, RoundToNearest(fltickrate));
	if (timeleft > 0)
		PrintToConsole(client, "Timeleft on %s: %s",g_szMapName, finalOutput);
	PrintToConsole(client, "Menu formatting is optimized for 1920x1080!");
	PrintToConsole(client, " ");
	PrintToConsole(client, "Client commands:");
	PrintToConsole(client, "!r, !stages, !s, !bonus, !b, !teleport, !stuck, !tele");
	PrintToConsole(client, "!help, !help2, !menu, !options, !profile, !compare,");
	PrintToConsole(client, "!maptop, !top, !start, !stop, !pause, !challenge, !surrender, !goto, !spec, !avg,");
	PrintToConsole(client, "!showsettings, !latest, !measure, !ranks, !flashlight, !language, !usp, !wr");
	PrintToConsole(client, "(options menu contains: !info");
	PrintToConsole(client, "!hide, !hidespecs, !disablegoto, !bhop)");
	PrintToConsole(client, "!hidechat, !hideweapon)");
	PrintToConsole(client, " ");
	PrintToConsole(client, "Live scoreboard:");
	PrintToConsole(client, "Kills: Time in seconds");
	PrintToConsole(client, "Assists: Number of % finished on current map")
	PrintToConsole(client, "Score: How many players are lower ranked than the player. Higher number means higher rank");
	PrintToConsole(client, "MVP Stars: Number of finished map runs on the current map");
	PrintToConsole(client, " ");
	PrintToConsole(client, "Skill groups:");
	PrintToConsole(client, "%s (%ip), %s (%ip), %s (%ip), %s (%ip)",g_szSkillGroups[1],g_pr_rank_Percentage[1],g_szSkillGroups[2], g_pr_rank_Percentage[2],g_szSkillGroups[3], g_pr_rank_Percentage[3],g_szSkillGroups[4], g_pr_rank_Percentage[4]);
	PrintToConsole(client, "%s (%ip), %s (%ip), %s (%ip), %s (%ip)",g_szSkillGroups[5], g_pr_rank_Percentage[5], g_szSkillGroups[6],g_pr_rank_Percentage[6], g_szSkillGroups[7], g_pr_rank_Percentage[7], g_szSkillGroups[8], g_pr_rank_Percentage[8]);
	PrintToConsole(client, "-----------------------------------------------------------------------------------------------------------");		
	PrintToConsole(client," ");
}
stock FakePrecacheSound( const String:szPath[] )
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

public SetStandingStartButton(client)
{	
	CreateButton(client,"climb_startbuttonx");
}


public SetStandingStopButton(client)
{
	CreateButton(client,"climb_endbuttonx");
}

public Action:BlockRadio(client, const String:command[], args) 
{
	if(!g_bRadioCommands && IsValidClient(client))
	{
		PrintToChat(client, "%t", "RadioCommandsDisabled", LIMEGREEN,WHITE);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public StringToUpper(String:input[]) 
{
	for(new i = 0; ; i++) 
	{
		if(input[i] == '\0') 
			return;
		input[i] = CharToUpper(input[i]);
	}
}

public GetServerInfo()
{
	new pieces[4];
	decl String:code2[3];
	decl String:NetIP[256];
	new longip = GetConVarInt(FindConVar("hostip"));
	new port = GetConVarInt( FindConVar( "hostport" ));
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	GeoipCountry(NetIP, g_szServerCountry, 100);

	if(!strcmp(g_szServerCountry, NULL_STRING))
		Format( g_szServerCountry, 100, "Unknown", g_szServerCountry );
	else				
		if( StrContains( g_szServerCountry, "United", false ) != -1 || 
			StrContains( g_szServerCountry, "Republic", false ) != -1 || 
			StrContains( g_szServerCountry, "Federation", false ) != -1 || 
			StrContains( g_szServerCountry, "Island", false ) != -1 || 
			StrContains( g_szServerCountry, "Netherlands", false ) != -1 || 
			StrContains( g_szServerCountry, "Isle", false ) != -1 || 
			StrContains( g_szServerCountry, "Bahamas", false ) != -1 || 
			StrContains( g_szServerCountry, "Maldives", false ) != -1 || 
			StrContains( g_szServerCountry, "Philippines", false ) != -1 || 
			StrContains( g_szServerCountry, "Vatican", false ) != -1 )
		{
			Format( g_szServerCountry, 100, "The %s", g_szServerCountry );
		}	
	if(GeoipCode2(NetIP, code2))
		Format(g_szServerCountryCode, 16, "%s",code2);
	else
		Format(g_szServerCountryCode, 16, "??",code2);
	Format(g_szServerIp, sizeof(g_szServerIp), "%s:%i",NetIP,port);
	GetConVarString(FindConVar("hostname"),g_szServerName,sizeof(g_szServerName));
}

public GetCountry(client)
{
	if(client != 0)
	{
		if(!IsFakeClient(client))
		{
			decl String:IP[16];
			decl String:code2[3];
			GetClientIP(client, IP, 16);
			
			//COUNTRY
			GeoipCountry(IP, g_szCountry[client], 100);     
			if(!strcmp(g_szCountry[client], NULL_STRING))
				Format( g_szCountry[client], 100, "Unknown", g_szCountry[client] );
			else				
				if( StrContains( g_szCountry[client], "United", false ) != -1 || 
					StrContains( g_szCountry[client], "Republic", false ) != -1 || 
					StrContains( g_szCountry[client], "Federation", false ) != -1 || 
					StrContains( g_szCountry[client], "Island", false ) != -1 || 
					StrContains( g_szCountry[client], "Netherlands", false ) != -1 || 
					StrContains( g_szCountry[client], "Isle", false ) != -1 || 
					StrContains( g_szCountry[client], "Bahamas", false ) != -1 || 
					StrContains( g_szCountry[client], "Maldives", false ) != -1 || 
					StrContains( g_szCountry[client], "Philippines", false ) != -1 || 
					StrContains( g_szCountry[client], "Vatican", false ) != -1 )
				{
					Format( g_szCountry[client], 100, "The %s", g_szCountry[client] );
				}				
			//CODE
			if(GeoipCode2(IP, code2))
			{
				Format(g_szCountryCode[client], 16, "%s",code2);		
			}
			else
				Format(g_szCountryCode[client], 16, "??");	
		}
	}
}

stock StripAllWeapons(client)
{
	new iEnt;
	for (new i = 0; i <= 5; i++)
	{
		if (i != 2)
			while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, iEnt);
				RemoveEdict(iEnt);
			}
	}
	if (GetPlayerWeaponSlot(client, 2) == -1)
		GivePlayerItem(client, "weapon_knife");
}

public MovementCheck(client)
{
	decl MoveType:mt;
	mt = GetEntityMoveType(client); 
	if (mt == MOVETYPE_FLYGRAVITY)
	{
		g_bTimeractivated[client] = false;
	}
}

public PlayButtonSound(client)
{
	if (!bSoundEnabled) 
 		return; 

	if (!IsFakeClient(client))
	{
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "play *buttons/button3.wav"); 
		ClientCommand(client, buffer); 	
	}
	//spec stop sound
	for(new i = 1; i <= MaxClients; i++) 
	{		
		if (IsValidClient(i) && !IsPlayerAlive(i))
		{			
			new SpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if (SpecMode == 4 || SpecMode == 5)
			{		
				new Target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");	
				if (Target == client)
				{
					decl String:szsound[255];
					Format(szsound, sizeof(szsound), "play *buttons/button3.wav"); 
					ClientCommand(i,szsound);
				}
			}					
		}
	}	
}
public DeleteButtons(client)
{
	decl String:classname[32];
	Format(classname,32,"prop_physics_override");
	for (new i; i < GetEntityCount(); i++)
    {
        if (IsValidEdict(i) && GetEntityClassname(i, classname, 32))
		{
			decl String:targetname[64];
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			if (StrEqual(targetname, "climb_startbuttonx", false) || StrEqual(targetname, "climb_endbuttonx", false))
			{
				if (StrEqual(targetname, "climb_startbuttonx", false))
				{
					g_fStartButtonPos[0] = -999999.9;
					g_fStartButtonPos[1] = -999999.9;
					g_fStartButtonPos[2] = -999999.9;
				}
				else
				{
					g_fEndButtonPos[0] = -999999.9;
					g_fEndButtonPos[1] = -999999.9;
					g_fEndButtonPos[2] = -999999.9;		
				}
				AcceptEntityInput(i, "Kill"); 
				RemoveEdict(i);
			}
		}	
	}
	Format(classname,32,"env_sprite");
	for (new i; i < GetEntityCount(); i++)
	{
        if (IsValidEdict(i) && GetEntityClassname(i, classname, 32))
		{
			decl String:targetname[64];
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			if (StrEqual(targetname, "starttimersign", false) || StrEqual(targetname, "stoptimersign", false))
			{
				AcceptEntityInput(i, "Kill");
				RemoveEdict(i);
			}
		}
	}
	g_bFirstEndButtonPush=true;
	g_bFirstStartButtonPush=true;
	//stop player times (global record fake)
	for (new i = 1; i <= MaxClients; i++)
	if (IsValidClient(i) && !IsFakeClient(i) && client != 67)	
	{
		Client_Stop(i,0);
	}
	if (IsValidClient(client))
		ckAdminMenu(client);
}

public CreateButton(client,String:targetname[]) 
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		//location (crosshair)
		new Float:locationPlayer[3];
		new Float:location[3];
		GetClientAbsOrigin(client, locationPlayer);
		GetClientEyePosition(client, location);
		new Float:ang[3];
		GetClientEyeAngles(client, ang);
		new Float:location2[3];
		location2[0] = (location[0]+(100*((Cosine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));
		location2[1] = (location[1]+(100*((Sine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));
		ang[0] -= (2*ang[0]);
		location2[2] = (location[2]+(100*(Sine(DegToRad(ang[0])))));
		location2[2] = locationPlayer[2];
	
		new ent = CreateEntityByName("prop_physics_override");
		if (ent != -1)
		{  
			DispatchKeyValue(ent, "model", "models/props/switch001.mdl");	
			DispatchKeyValue(ent, "spawnflags", "264");
			DispatchKeyValue(ent, "targetname",targetname);
			DispatchSpawn(ent);  
			ang[0] = 0.0;
			ang[1] += 180.0;
			TeleportEntity(ent, location2, ang, NULL_VECTOR);
			SDKHook(ent, SDKHook_UsePost, OnUsePost);	
			if (StrEqual(targetname, "climb_startbuttonx"))
				PrintToChat(client,"%c[%cCK%c] Start button built!", WHITE,MOSSGREEN,WHITE);
			else
				PrintToChat(client,"%c[%cCK%c] Stop button built!", WHITE,MOSSGREEN,WHITE);
			ang[1] -= 180.0;
		}
		new sprite = CreateEntityByName("env_sprite");
		if(sprite != -1) 
		{ 
			DispatchKeyValue(sprite, "classname", "env_sprite");
			DispatchKeyValue(sprite, "spawnflags", "1");
			DispatchKeyValue(sprite, "scale", "0.2");
			if (StrEqual(targetname, "climb_startbuttonx"))
			{
				DispatchKeyValue(sprite, "model", "materials/models/props/startkztimer.vmt"); 
				DispatchKeyValue(sprite, "targetname", "starttimersign");
			}
			else
			{
				DispatchKeyValue(sprite, "model", "materials/models/props/stopkztimer.vmt"); 
				DispatchKeyValue(sprite, "targetname", "stoptimersign");
			}
			DispatchKeyValue(sprite, "rendermode", "1");
			DispatchKeyValue(sprite, "framerate", "0");
			DispatchKeyValue(sprite, "HDRColorScale", "1.0");
			DispatchKeyValue(sprite, "rendercolor", "255 255 255");
			DispatchKeyValue(sprite, "renderamt", "255");
			DispatchSpawn(sprite);
			location = location2;	
			location[2]+=95;
			ang[0] = 0.0;
			TeleportEntity(sprite, location, ang, NULL_VECTOR);
		}
		
		if (StrEqual(targetname, "climb_startbuttonx"))
		{
			db_updateMapButtons(location2[0],location2[1],location2[2],ang[1],0);
			g_fStartButtonPos = location2;
		}
		else
		{
			db_updateMapButtons(location2[0],location2[1],location2[2],ang[1],1);
			g_fEndButtonPos =  location2;
		}
	}
	else
		PrintToChat(client, "%t", "AdminSetButton", MOSSGREEN,WHITE); 
	ckAdminMenu(client);
}

public FixPlayerName(client)
{
	decl String:szName[64];
	decl String:szOldName[64];
	GetClientName(client,szName,64);
	Format(szOldName, 64,"%s ",szName);
	ReplaceChar("'", "`", szName);
	if (!(StrEqual(szOldName,szName)))
	{
		SetClientInfo(client, "name", szName);
		SetEntPropString(client, Prop_Data, "m_szNetname", szName);
		CS_SetClientName(client, szName);
	}
}

public SetClientDefaults(client)
{	
	g_fLastOverlay[client] = GetEngineTime() - 5.0;	
	g_bProfileSelected[client]=false;
	g_bNewReplay[client] = false;
	g_bFirstButtonTouch[client]=true;
	g_pr_Calculating[client] = false;
	g_bTimeractivated[client] = false;	
	g_bKickStatus[client] = false;
	g_specToStage[client] = false;
	g_bSpectate[client] = false;	
	if (!g_bLateLoaded)
		g_bFirstTeamJoin[client] = true;	
	g_bFirstSpawn[client] = true;
	g_bSayHook[client] = false;
	g_bRespawnAtTimer[client] = false;
	g_bRecalcRankInProgess[client] = false;
	g_bPause[client] = false;
	g_bPositionRestored[client] = false;
	g_bPauseWasActivated[client]=false;
	g_bRestorePosition[client] = false;
	g_bRestorePositionMsg[client] = false;
	g_bRespawnPosition[client] = false;
	g_bNoClip[client] = false;		
	g_bMapFinished[client] = false;
	g_bMapRankToChat[client] = false;
	g_bChallenge[client] = false;
	g_bOverlay[client]=false;
	g_bBonusTimer[client] = false;
	g_bChallenge_Request[client] = false;
	g_bClientOwnReason[client] = false;
	g_AdminMenuLastPage[client] = 0;
	g_OptionsMenuLastPage[client] = 0;	
	g_MenuLevel[client] = -1;
	g_AttackCounter[client] = 0;
	g_SpecTarget[client] = -1;
	g_pr_points[client] = 0;
	g_fCurrentRunTime[client] = -1.0;
	g_fPlayerCordsLastPosition[client] = Float:{0.0,0.0,0.0};
	g_fPlayerConnectedTime[client] = GetEngineTime();			
	g_fLastTimeButtonSound[client] = GetEngineTime();
	g_fLastTimeNoClipUsed[client] = -1.0;
	g_fStartTime[client] = -1.0;
	g_fPlayerLastTime[client] = -1.0;
	g_fPauseTime[client] = 0.0;
	g_MapRank[client] = 99999;
	g_OldMapRank[client] = 99999;
	g_PlayerRank[client] = 99999;	
	g_fProfileMenuLastQuery[client] = GetEngineTime();
	Format(g_szPlayerPanelText[client], 512, "");
	Format(g_pr_rankname[client], 32, "");
	g_PlayerChatRank[client] = -1;
	Format(g_szCurrentStage[client], 12, "1");
	Format(g_szPersonalRecord[client], 32, "");
	Format(g_szPersonalRecordBonus[client], 32, "");
	bClientInStartZone[client]=false;
	bClientInSpeedZone[client]=false;
	g_bValidRun[client] = false;
	g_fMaxPercCompleted[client] = 0.0;

	// Client options
	g_bInfoPanel[client]=true;
	g_bShowNames[client]=true; 
	g_bGoToClient[client]=true; 
	g_bShowTime[client]=false; 
	g_bHide[client]=false; 
	g_bStartWithUsp[client] = false;
	g_bShowSpecs[client]=true;
	g_bAutoBhopClient[client]=true;
	g_bHideChat[client]=false;
	g_bViewModel[client]=true;
}


// - Get Runtime -
public GetcurrentRunTime(client)
{
	g_fCurrentRunTime[client] = GetEngineTime() - g_fStartTime[client] - g_fPauseTime[client];	
	if (g_bPause[client])
		Format(g_szTimerTitle[client], 255, "%s\nTimer on Hold", g_szPlayerPanelText[client]);
	else
	{
		decl String:szTime[32];
		FormatTimeFloat(client, g_fCurrentRunTime[client], 1,szTime,sizeof(szTime));
		if(g_bShowTime[client])
		{	
			if(StrEqual(g_szPlayerPanelText[client],""))		
				Format(g_szTimerTitle[client], 255, "%s", szTime);
			else
				Format(g_szTimerTitle[client], 255, "%s\n%s", g_szPlayerPanelText[client],szTime);
		}
		else
			Format(g_szTimerTitle[client], 255, "%s",g_szPlayerPanelText[client]);
	}	
}

public Float:GetSpeed(client)
{
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	new Float:speed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	return speed;
}


public Float:GetVelocity(client)
{
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	new Float:speed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)+Pow(fVelocity[2],2.0));
	return speed;
}



public SetCashState()
{
	ServerCommand("mp_startmoney 0; mp_playercashawards 0; mp_teamcashawards 0");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			SetEntProp(i, Prop_Send, "m_iAccount", 0);
	}
}

public PlayRecordSound(iRecordtype)
{
	decl String:buffer[255];
	if (iRecordtype==1)
	{
	    for(new i = 1; i <= GetMaxClients(); i++) 
		{ 
			if(IsValidClient(i) && !IsFakeClient(i) && g_bEnableQuakeSounds[i] == true) 
			{ 
				Format(buffer, sizeof(buffer), "play %s", PRO_RELATIVE_SOUND_PATH); 
				ClientCommand(i, buffer); 
			}
		} 
	}
	else
		if (iRecordtype==2 || iRecordtype == 3)
		{
			for(new i = 1; i <= GetMaxClients(); i++) 
			{ 
				if(IsValidClient(i) && !IsFakeClient(i) && g_bEnableQuakeSounds[i] == true) 
				{ 
					Format(buffer, sizeof(buffer), "play %s", CP_RELATIVE_SOUND_PATH); 
					ClientCommand(i, buffer); 
				}
			}
		}
}

public PlayUnstoppableSound(client)
{
	decl String:buffer[255];
	Format(buffer, sizeof(buffer), "play %s", UNSTOPPABLE_RELATIVE_SOUND_PATH); 
	if (!IsFakeClient(client) && g_bEnableQuakeSounds[client])
		ClientCommand(client, buffer); 	
	//spec stop sound
	for(new i = 1; i <= MaxClients; i++) 
	{		
		if (IsValidClient(i) && !IsPlayerAlive(i))
		{			
			new SpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if (SpecMode == 4 || SpecMode == 5)
			{		
				new Target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");	
				if (Target == client && g_bEnableQuakeSounds[i])
					ClientCommand(i,buffer);
			}					
		}
	}	
}


public InitPrecache()
{
	AddFileToDownloadsTable( UNSTOPPABLE_SOUND_PATH );
	FakePrecacheSound( UNSTOPPABLE_RELATIVE_SOUND_PATH );	
	AddFileToDownloadsTable( PRO_FULL_SOUND_PATH );
	FakePrecacheSound( PRO_RELATIVE_SOUND_PATH );	
	AddFileToDownloadsTable( PRO_FULL_SOUND_PATH );
	FakePrecacheSound( PRO_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( CP_FULL_SOUND_PATH );
	FakePrecacheSound( CP_RELATIVE_SOUND_PATH );	
	AddFileToDownloadsTable("models/props/switch001.mdl");
	AddFileToDownloadsTable("models/props/switch001.vvd");
	AddFileToDownloadsTable("models/props/switch001.phy");
	AddFileToDownloadsTable("models/props/switch001.vtx");
	AddFileToDownloadsTable("models/props/switch001.dx90.vtx");		
	AddFileToDownloadsTable("materials/models/props/switch.vmt");
	AddFileToDownloadsTable("materials/models/props/switch.vtf");
	AddFileToDownloadsTable("materials/models/props/switch001.vmt");
	AddFileToDownloadsTable("materials/models/props/switch001.vtf");
	AddFileToDownloadsTable("materials/models/props/switch001_normal.vmt");
	AddFileToDownloadsTable("materials/models/props/switch001_normal.vtf");
	AddFileToDownloadsTable("materials/models/props/switch001_lightwarp.vmt");
	AddFileToDownloadsTable("materials/models/props/switch001_lightwarp.vtf");
	AddFileToDownloadsTable("materials/models/props/switch001_exponent.vmt");
	AddFileToDownloadsTable("materials/models/props/switch001_exponent.vtf");
	AddFileToDownloadsTable("materials/models/props/startkztimer.vmt");
	AddFileToDownloadsTable("materials/models/props/startkztimer.vtf");	
	AddFileToDownloadsTable("materials/models/props/stopkztimer.vmt");
	AddFileToDownloadsTable("materials/models/props/stopkztimer.vtf");
	AddFileToDownloadsTable("materials/sprites/bluelaser1.vmt");
	AddFileToDownloadsTable("materials/sprites/bluelaser1.vtf");
	AddFileToDownloadsTable("materials/sprites/laser.vmt");
	AddFileToDownloadsTable("materials/sprites/laser.vtf");
	AddFileToDownloadsTable("materials/sprites/halo01.vmt");
	AddFileToDownloadsTable("materials/sprites/halo01.vtf");
	AddFileToDownloadsTable(g_sArmModel);
	AddFileToDownloadsTable(g_sPlayerModel);
	AddFileToDownloadsTable(g_sReplayBotArmModel);
	AddFileToDownloadsTable(g_sReplayBotPlayerModel);
	AddFileToDownloadsTable(g_sReplayBotArmModel2);
	AddFileToDownloadsTable(g_sReplayBotPlayerModel2);
	g_Beam[0] = PrecacheModel("materials/sprites/laser.vmt", true);
	g_Beam[1] = PrecacheModel("materials/sprites/halo01.vmt", true);
	g_Beam[2] = PrecacheModel("materials/sprites/bluelaser1.vmt", true);
	PrecacheModel("materials/models/props/startkztimer.vmt",true);
	PrecacheModel("materials/models/props/stopkztimer.vmt",true);
	PrecacheModel("models/props/switch001.mdl",true);	
	PrecacheModel(g_sReplayBotArmModel,true);
	PrecacheModel(g_sReplayBotPlayerModel,true);
	PrecacheModel(g_sArmModel,true);
	PrecacheModel(g_sPlayerModel,true);
}


// thx to V952 https://forums.alliedmods.net/showthread.php?t=212886
stock TraceClientViewEntity(client)
{
	new Float:m_vecOrigin[3];
	new Float:m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	new Handle:tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	new pEntity = -1;
	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	CloseHandle(tr);
	return -1;
}

// thx to V952 https://forums.alliedmods.net/showthread.php?t=212886
public bool:TRDontHitSelf(entity, mask, any:data)
{
	if (entity == data)
		return false;
	return true;
}

public PrintMapRecords(client)
{
	decl String:szTime[32];
	if (g_fRecordMapTime != 9999999.0)
	{
		FormatTimeFloat(client, g_fRecordMapTime, 3,szTime,sizeof(szTime));
		PrintToChat(client, "%t", "MapRecord",MOSSGREEN,WHITE,DARKBLUE,WHITE, szTime, g_szRecordPlayer); 
	}	
	if (g_fBonusFastest != 9999999.0) // BONUS
	{
		FormatTimeFloat(client, g_fBonusFastest, 3, szTime, sizeof(szTime));
		PrintToChat(client, "%t", "BonusRecord", MOSSGREEN,WHITE,YELLOW,WHITE,szTime,szBonusFastest); 
	}
}

public MapFinishedMsgs(client, type)
{	
	if (IsValidClient(client))
	{
		decl String:szTime[32];
		decl String:szName[MAX_NAME_LENGTH];
		GetClientName(client, szName, MAX_NAME_LENGTH);
		new count;
		new rank;
		if (type==1)
		{
			count = g_MapTimesCount;
			rank = g_MapRank[client];
			FormatTimeFloat(client, g_fRecordMapTime, 3, szTime, sizeof(szTime));	
		}
		for(new i = 1; i <= GetMaxClients(); i++) 
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				if (g_Time_Type[client] == 1)
				{
					PrintToChat(i, "%t", "MapFinished1",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,DARKBLUE,GRAY,LIMEGREEN, g_szFinalTime[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE); 
					PrintToConsole(i, "%s finished the map with a time of (%s). [rank #%i/%i | record %s]",szName,g_szFinalTime[client],rank,count,szTime);  
				}			
				else
					if (g_Time_Type[client] == 3)
					{
						PrintToChat(i, "%t", "MapFinished3",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,DARKBLUE,GRAY,LIMEGREEN, g_szFinalTime[client],GRAY,GREEN, g_szTimeDifference[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE);  				
						PrintToConsole(i, "%s finished the map with a time of (%s). Improving their best time by (%s).  [rank #%i/%i | record %s]",szName,g_szFinalTime[client],g_szTimeDifference[client],rank,count,szTime); 	
					}
					else
						if (g_Time_Type[client] == 5)
						{
							PrintToChat(i, "%t", "MapFinished5",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,DARKBLUE,GRAY,LIMEGREEN, g_szFinalTime[client],GRAY,RED, g_szTimeDifference[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE);  	
							PrintToConsole(i, "%s finished the map with a time of (%s). Missing their best time by (%s).  [rank #%i/%i | record %s]",szName,g_szFinalTime[client],g_szTimeDifference[client],rank,count,szTime); 
						}

				if (g_FinishingType[client] == 2)				
				{
					PrintToChat(i, "%t", "NewMapRecord",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,DARKBLUE);  
					PrintToConsole(i, "[CK] %s scored a new MAP RECORD",szName); 	
				}				
			}
		
		if (rank==99999 && IsValidClient(client))
			PrintToChat(client, "[%cCK%c] %cFailed to save your data correctly! Please contact an admin.",MOSSGREEN,WHITE,DARKRED,RED,DARKRED); 	
		
		
		//noclip MsgMsg
		if (IsValidClient(client) && g_bMapFinished[client] == false && !StrEqual(g_pr_rankname[client],g_szSkillGroups[8]) && !(GetUserFlagBits(client) & ADMFLAG_RESERVATION) && !(GetUserFlagBits(client) & ADMFLAG_ROOT) && !(GetUserFlagBits(client) & ADMFLAG_GENERIC) && g_bNoClipS)
			PrintToChat(client, "%t", "NoClipUnlocked",MOSSGREEN,WHITE,YELLOW);
		g_bMapFinished[client] = true;
		CreateTimer(0.0, UpdatePlayerProfile, client,TIMER_FLAG_NO_MAPCHANGE);
		g_fStartTime[client] = -1.0;	
		
		if (g_Time_Type[client] == 0 || g_Time_Type[client] == 1 || g_Time_Type[client] == 2 || g_Time_Type[client] == 3)
			CheckMapRanks(client);			
	
		//sound all
		PlayRecordSound(g_Sound_Type[client]);			
	
		//sound Client
		if (g_Sound_Type[client] == 5)
			PlayUnstoppableSound(client);
	}
	//recalc avg
	db_CalcAvgRunTime();
}
// TODO remove tps from call
public CheckMapRanks(client)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsValidClient(i) && !IsFakeClient(i) && i != client)	
	{	
		if (g_OldMapRank[client] < g_MapRank[client] && g_OldMapRank[client] > g_MapRank[i] && g_MapRank[client] <= g_MapRank[i])
			g_MapRank[i]++;			
	}
}

public ReplaceChar(String:sSplitChar[], String:sReplace[], String:sString[64])
{
	StrCat(sString, sizeof(sString), " ");
	new String:sBuffer[16][256];
	ExplodeString(sString, sSplitChar, sBuffer, sizeof(sBuffer), sizeof(sBuffer[]));
	strcopy(sString, sizeof(sString), "");
	for (new i = 0; i < sizeof(sBuffer); i++)
	{
		if (strcmp(sBuffer[i], "") == 0)
			continue;
		if (i != 0)
		{
			new String:sTmpStr[256];
			Format(sTmpStr, sizeof(sTmpStr), "%s%s", sReplace, sBuffer[i]);
			StrCat(sString, sizeof(sString), sTmpStr);
		}
		else
		{
			StrCat(sString, sizeof(sString), sBuffer[i]);
		}
	}
}

public FormatTimeFloat(client, Float:time, type, String:string[], length)
{
	decl String:szMilli[16];
	decl String:szSeconds[16];
	decl String:szMinutes[16];
	decl String:szHours[16];
	decl String:szMilli2[16];
	decl String:szSeconds2[16];
	decl String:szMinutes2[16];
	new imilli;
	new imilli2;
	new iseconds;
	new iminutes;
	new ihours;
	time = FloatAbs(time);
	imilli = RoundToZero(time*100);
	imilli2 = RoundToZero(time*10);
	imilli = imilli%100;
	imilli2 = imilli2%10;
	iseconds = RoundToZero(time);
	iseconds = iseconds%60;	
	iminutes = RoundToZero(time/60);	
	iminutes = iminutes%60;	
	ihours = RoundToZero((time/60)/60);

	if (imilli < 10)
		Format(szMilli, 16, "0%dms", imilli);
	else
		Format(szMilli, 16, "%dms", imilli);
	if (iseconds < 10)
		Format(szSeconds, 16, "0%ds", iseconds);
	else
		Format(szSeconds, 16, "%ds", iseconds);
	if (iminutes < 10)
		Format(szMinutes, 16, "0%dm", iminutes);
	else
		Format(szMinutes, 16, "%dm", iminutes);	
		
	
	Format(szMilli2, 16, "%d", imilli2);
	if (iseconds < 10)
		Format(szSeconds2, 16, "0%d", iseconds);
	else
		Format(szSeconds2, 16, "%d", iseconds);
	if (iminutes < 10)
		Format(szMinutes2, 16, "0%d", iminutes);
	else
		Format(szMinutes2, 16, "%d", iminutes);	
	//Time: 00m 00s 00ms
	if (type==0)
	{
		Format(szHours, 16, "%dm", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%d", ihours);
			if (g_bClimbersMenuOpen[client])
			{
				Format(string, length, "%s:%s:%s.%s", szHours, szMinutes2,szSeconds2,szMilli2);
			}
			else
				Format(string, length, "%s:%s:%s.%s", szHours, szMinutes2,szSeconds2,szMilli2);
		}
		else
		{
			if (g_bClimbersMenuOpen[client])
			{
				Format(string, length, "%s:%s.%s", szMinutes2,szSeconds2,szMilli2);
			}
			else
				Format(string, length, "%s:%s.%s", szMinutes2,szSeconds2,szMilli2);
		}
	}
	//00m 00s 00ms
	if (type==1)
	{
		Format(szHours, 16, "%dm", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%dh", ihours);
			Format(string, length, "%s %s %s %s", szHours, szMinutes,szSeconds,szMilli);
		}
		else
			Format(string, length, "%s %s %s", szMinutes,szSeconds,szMilli);	
	}
	else
	//00h 00m 00s 00ms
	if (type==2)
	{
		imilli = RoundToZero(time*1000);
		imilli = imilli%1000;
		if (imilli < 10)
			Format(szMilli, 16, "00%dms", imilli);
		else
		if (imilli < 100)
			Format(szMilli, 16, "0%dms", imilli);
		else
			Format(szMilli, 16, "%dms", imilli);
		Format(szHours, 16, "%dh", ihours);
		Format(string, 32, "%s %s %s %s",szHours, szMinutes,szSeconds,szMilli);
	}
	else
	//00:00:00
	if (type==3)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "%s:%s:%s:%s", szHours, szMinutes,szSeconds,szMilli);
		}
		else
			Format(string, length, "%s:%s:%s", szMinutes,szSeconds,szMilli);	
	}
	//Time: 00:00:00
	if (type==4)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "Time: %s:%s:%s", szHours, szMinutes,szSeconds);
		}
		else
			Format(string, length, "Time: %s:%s", szMinutes,szSeconds);	
	}
	// goes to  00:00
	if (type==5)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);	
		if (ihours>0)	
		{

			Format(szHours, 16, "%d", ihours);
			Format(string, length, "%s:%s:%s:%s", szHours, szMinutes,szSeconds,szMilli);
		}
		else
			if (iminutes>0)
				Format(string, length, "%s:%s:%s", szMinutes,szSeconds,szMilli);
			else
				Format(string, length, "%s:%ss", szSeconds, szMilli);
	}
}

public SetPlayerRank(client)
{
	if (IsFakeClient(client))
		return;
	if (g_bPointSystem)
	{
		if (g_pr_points[client] < g_pr_rank_Percentage[1])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[0]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",WHITE,g_szSkillGroups[0],WHITE);
			g_PlayerChatRank[client] = 0;
		}
		else
		if (g_pr_rank_Percentage[1] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[2])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[1]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",WHITE,g_szSkillGroups[1],WHITE);
			g_PlayerChatRank[client] = 1;
		}
		else
		if (g_pr_rank_Percentage[2] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[3])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[2]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",GRAY,g_szSkillGroups[2],WHITE);
			g_PlayerChatRank[client] = 2;		
		}
		else
		if (g_pr_rank_Percentage[3] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[4])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[3]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",LIGHTBLUE,g_szSkillGroups[3],WHITE);
			g_PlayerChatRank[client] = 3;		
		}
		else
		if (g_pr_rank_Percentage[4] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[5])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[4]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",BLUE,g_szSkillGroups[4],WHITE);
			g_PlayerChatRank[client] = 4;
		}
		else
		if (g_pr_rank_Percentage[5] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[6])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[5]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",DARKBLUE,g_szSkillGroups[5],WHITE);
			g_PlayerChatRank[client] = 5;
		}
		else
		if (g_pr_rank_Percentage[6] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[7])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[6]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",PINK,g_szSkillGroups[6],WHITE);
			g_PlayerChatRank[client] = 6;
		}
		else
		if (g_pr_rank_Percentage[7] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[8])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[7]);	
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",LIGHTRED,g_szSkillGroups[7],WHITE);
			g_PlayerChatRank[client] = 7;
		}
		else
		if (g_pr_points[client] >= g_pr_rank_Percentage[8])
		{
			Format(g_pr_rankname[client], 32, "[%s]",g_szSkillGroups[8]);	
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",DARKRED,g_szSkillGroups[8],WHITE);
			g_PlayerChatRank[client] = 8;
		}
	}	
	else
	{
		Format(g_pr_rankname[client], 32, "");
		g_PlayerChatRank[client] = -1;
	}

		
	// VIP Clantag
	if (g_bVipClantag)			
		if ((GetUserFlagBits(client) & ADMFLAG_RESERVATION) && !(GetUserFlagBits(client) & ADMFLAG_ROOT) && !(GetUserFlagBits(client) & ADMFLAG_GENERIC))
		{
			Format(g_pr_chat_coloredrank[client], 32, "%s %cVIP%c",g_pr_chat_coloredrank[client],YELLOW,WHITE);
			Format(g_pr_rankname[client], 32, "VIP");	
		//	g_PlayerChatRank[client] = 9;
		}

	// Admin Clantag
	if (g_bAdminClantag)
	{	if (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ADMFLAG_GENERIC) 
		{		
			Format(g_pr_chat_coloredrank[client], 32, "%s %cADMIN%c",g_pr_chat_coloredrank[client],LIMEGREEN,WHITE);
			Format(g_pr_rankname[client], 32, "ADMIN");	
		//	g_PlayerChatRank[client] = 10;
			return;
		}
	}
	
	// MAPPER Clantag
	for (new x = 0; x < 100; x++)
	{
		if ((StrContains(g_szMapmakers[x],"STEAM",true) != -1))
		{
			if (StrEqual(g_szMapmakers[x],g_szSteamID[client]))
			{		
				Format(g_pr_chat_coloredrank[client], 32, "%s %cMAPPER%c",g_pr_chat_coloredrank[client],LIMEGREEN,WHITE);
				Format(g_pr_rankname[client], 32, "MAPPER");
			//	g_PlayerChatRank[client] = 11;			
				break;
			}		
		}
	}			
}
stock Action:PrintSpecMessageAll(client)
{
	decl String:szName[64];
	GetClientName(client, szName, sizeof(szName));
	ReplaceString(szName,64,"{darkred}","",false);
	ReplaceString(szName,64,"{green}","",false);
	ReplaceString(szName,64,"{lightgreen}","",false);
	ReplaceString(szName,64,"{blue}","",false);
	ReplaceString(szName,64,"{olive}","",false);
	ReplaceString(szName,64,"{lime}","",false);
	ReplaceString(szName,64,"{red}","",false);
	ReplaceString(szName,64,"{purple}","",false);
	ReplaceString(szName,64,"{grey}","",false);
	ReplaceString(szName,64,"{yellow}","",false);
	ReplaceString(szName,64,"{lightblue}","",false);
	ReplaceString(szName,64,"{steelblue}","",false);
	ReplaceString(szName,64,"{darkblue}","",false);
	ReplaceString(szName,64,"{pink}","",false);
	ReplaceString(szName,64,"{lightred}","",false);
	decl String:szTextToAll[1024];
	GetCmdArgString(szTextToAll, sizeof(szTextToAll));
	StripQuotes(szTextToAll);
	if (StrEqual(szTextToAll,"") || StrEqual(szTextToAll," ") || StrEqual(szTextToAll,"  "))
		return Plugin_Handled;

	ReplaceString(szTextToAll,1024,"{darkred}","",false);
	ReplaceString(szTextToAll,1024,"{green}","",false);
	ReplaceString(szTextToAll,1024,"{lightgreen}","",false);
	ReplaceString(szTextToAll,1024,"{blue}","",false);
	ReplaceString(szTextToAll,1024,"{olive}","",false);
	ReplaceString(szTextToAll,1024,"{lime}","",false);
	ReplaceString(szTextToAll,1024,"{red}","",false);
	ReplaceString(szTextToAll,1024,"{purple}","",false);
	ReplaceString(szTextToAll,1024,"{grey}","",false);
	ReplaceString(szTextToAll,1024,"{yellow}","",false);
	ReplaceString(szTextToAll,1024,"{lightblue}","",false);
	ReplaceString(szTextToAll,1024,"{steelblue}","",false);
	ReplaceString(szTextToAll,1024,"{darkblue}","",false);
	ReplaceString(szTextToAll,1024,"{pink}","",false);
	ReplaceString(szTextToAll,1024,"{lightred}","",false);
	
	decl String:szChatRank[64];
	Format(szChatRank, 64, "%s",g_pr_chat_coloredrank[client]);

	if (g_bPointSystem && g_bColoredNames)
	{
		switch(g_PlayerChatRank[client])
		{
			case 0: // 1st Rank
				Format(szName, 64, "%c%s", WHITE, szName);
			case 1:
				Format(szName, 64, "%c%s", WHITE, szName);
			case 2:
				Format(szName, 64, "%c%s", GRAY, szName);
			case 3:
				Format(szName, 64, "%c%s", LIGHTBLUE, szName);
			case 4:
				Format(szName, 64, "%c%s", BLUE, szName);
			case 5:
				Format(szName, 64, "%c%s", DARKBLUE, szName);
			case 6:
				Format(szName, 64, "%c%s", PINK, szName);
			case 7:
				Format(szName, 64, "%c%s", LIGHTRED, szName);
			case 8: // Highest rank
				Format(szName, 64, "%c%s", DARKRED, szName);
		/*	case 9: // Admin
				Format(szName, 64, "%c%s", GREEN, szName);
			case 10: // VIP
				Format(szName, 64, "%c%s", MOSSGREEN, szName);
			case 11: // Mapper
				Format(szName, 64, "%c%s", YELLOW, szName);*/
		}
	}
			
	if (g_bCountry && (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag)))		
		CPrintToChatAll("{green}%s{default} %s *SPEC* {grey}%s{default}: %s",g_szCountryCode[client], szChatRank, szName,szTextToAll);
	else
		if (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag))
			CPrintToChatAll("%s *SPEC* {grey}%s{default}: %s", szChatRank,szName,szTextToAll);
		else
			if (g_bCountry)
				CPrintToChatAll("[{green}%s{default}] *SPEC* {grey}%s{default}: %s", g_szCountryCode[client],szName, szTextToAll);
			else		
				CPrintToChatAll("*SPEC* {grey}%s{default}: %s", szName, szTextToAll);
	for (new i = 1; i <= MaxClients; i++)
		if (IsValidClient(i))	
		{
			if (g_bCountry && (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag)))
				PrintToConsole(i, "%s [%s] *SPEC* %s: %s", g_szCountryCode[client],g_pr_rankname[client],szName, szTextToAll);
			else	
				if (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag))
					PrintToConsole(i, "[%s] *SPEC* %s: %s", g_szCountryCode[client],szName, szTextToAll);		
				else
					if (g_bPointSystem)
						PrintToConsole(i, "[%s] *SPEC* %s: %s", g_pr_rankname[client],szName, szTextToAll);	
						else
							PrintToConsole(i, "*SPEC* %s: %s", szName, szTextToAll);
		}
	return Plugin_Handled;
}
//http://pastebin.com/YdUWS93H
public bool:CheatFlag(const String:voice_inputfromfile[], bool:isCommand, bool:remove)
{
	if(remove)
	{
		if (!isCommand)
		{
			new Handle:hConVar = FindConVar(voice_inputfromfile);
			if (hConVar != INVALID_HANDLE)
			{
				new flags = GetConVarFlags(hConVar);
				SetConVarFlags(hConVar, flags &= ~FCVAR_CHEAT);
				return true;
			} 
			else 
				return false;			
		} 
		else 
		{
			new flags = GetCommandFlags(voice_inputfromfile);
			if (SetCommandFlags(voice_inputfromfile, flags &= ~FCVAR_CHEAT))
				return true;
			else 
				return false;
		}
	}
	else
	{
		if (!isCommand)
		{
			new Handle:hConVar = FindConVar(voice_inputfromfile);
			if (hConVar != INVALID_HANDLE)
			{
				new flags = GetConVarFlags(hConVar);
				SetConVarFlags(hConVar, flags & FCVAR_CHEAT);
				return true;
			}
			else 
				return false;
			
			
		} else
		{
			new flags = GetCommandFlags(voice_inputfromfile);
			if (SetCommandFlags(voice_inputfromfile, flags & FCVAR_CHEAT))	
				return true;
			else 
				return false;
				
		}
	}
}

public PlayerPanel(client)
{	
	if (!IsValidClient(client) || IsFakeClient(client))
		return;
	
	if (GetClientMenu(client) == MenuSource_None)
	{
		g_bMenuOpen[client] = false;
		g_bClimbersMenuOpen[client] = false;		
	}	
	else
		return;

	if (g_bTimeractivated[client])
	{
		GetcurrentRunTime(client);
		if(!StrEqual(g_szTimerTitle[client],""))		
		{
			new Handle:panel = CreatePanel();
			DrawPanelText(panel, g_szTimerTitle[client]);
			SendPanelToClient(panel, client, PanelHandler, 1);
			CloseHandle(panel);
		}
	}
}

public GetRGBColor(bot, String:color[256])
{
	decl String:sPart[4];
	new iFirstSpace = FindCharInString(color, ' ', false) + 1;
	new iLastSpace  = FindCharInString(color, ' ', true) + 1;
	if (bot == 0)
	{
		strcopy(sPart, iFirstSpace, color);
		g_ReplayBotColor[0] = StringToInt(sPart);
		strcopy(sPart, iLastSpace - iFirstSpace, color[iFirstSpace]);
		g_ReplayBotColor[1] = StringToInt(sPart);
		strcopy(sPart, strlen(color) - iLastSpace + 1, color[iLastSpace]);
		g_ReplayBotColor[2] = StringToInt(sPart);
	}
	else
		if (bot == 1)
		{
			strcopy(sPart, iFirstSpace, color);
			g_BonusBotColor[0] = StringToInt(sPart);
			strcopy(sPart, iLastSpace - iFirstSpace, color[iFirstSpace]);
			g_BonusBotColor[1] = StringToInt(sPart);
			strcopy(sPart, strlen(color) - iLastSpace + 1, color[iLastSpace]);
			g_BonusBotColor[2] = StringToInt(sPart);
		}
	
	if (bot == 0 && g_RecordBot != -1 && IsValidClient(g_RecordBot))
		SetEntityRenderColor(g_RecordBot, g_ReplayBotColor[0], g_ReplayBotColor[1], g_ReplayBotColor[2], 50);
	else
		if (bot == 1 && g_BonusBot != -1 && IsValidClient(g_BonusBot))
			SetEntityRenderColor(g_BonusBot, g_BonusBotColor[0], g_BonusBotColor[1], g_BonusBotColor[2], 50);

}

public SpecList(client)
{
	if (!IsValidClient(client) || g_bTopMenuOpen[client]  || IsFakeClient(client))
		return;
		
	if (GetClientMenu(client) == MenuSource_None)
	{
		g_bMenuOpen[client] = false;
		g_bClimbersMenuOpen[client] = false;		
	}
	else
		return;

	if (g_bTimeractivated[client] && !g_bSpectate[client]) 
		return; 
	if (g_bMenuOpen[client] || g_bClimbersMenuOpen[client]) 
		return;
	if(!StrEqual(g_szPlayerPanelText[client],""))
	{
		new Handle:panel = CreatePanel();
		DrawPanelText(panel, g_szPlayerPanelText[client]);
		SendPanelToClient(panel, client, PanelHandler, 1);
		CloseHandle(panel);
	}
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public bool:TraceRayDontHitSelf(entity, mask, any:data) 
{
	return (entity != data);
}

stock bool:IntoBool(status)
{
	if(status > 0)
		return true;
	else
		return false;
}

stock BooltoInt(bool:status)
{
	if(status)
		return 1;
	else
		return 0;
}

public PlayQuakeSound_Spec(client, String:buffer[255])
{
	new SpecMode;
	for(new x = 1; x <= MaxClients; x++) 
	{
		if (IsValidClient(x) && !IsPlayerAlive(x))
		{			
			SpecMode = GetEntProp(x, Prop_Send, "m_iObserverMode");
			if (SpecMode == 4 || SpecMode == 5)
			{		
				new Target = GetEntPropEnt(x, Prop_Send, "m_hObserverTarget");	
				if (Target == client)
					if (g_bEnableQuakeSounds[x])
						ClientCommand(x, buffer); 
			}					
		}		
	}
}


public HookCheck(client)
{
	if (g_bHookMod)
	{
		if (HGR_IsHooking(client) || HGR_IsGrabbing(client) || HGR_IsBeingGrabbed(client) || HGR_IsRoping(client) || HGR_IsPushing(client))
		{
			g_bTimeractivated[client] = false;
		}
	}
}

public AttackProtection(client, &buttons)
{
	if (g_bAttackSpamProtection)
	{
		decl String:classnamex[64];
		GetClientWeapon(client, classnamex, 64);
		if(StrContains(classnamex,"knife",true) == -1 && g_AttackCounter[client] >= 40)
		{
			if(buttons & IN_ATTACK)
			{
				decl ent; 
				ent = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
			}
		}
	}	
}

public MenuTitleRefreshing(client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;
		
	if (GetClientMenu(client) == MenuSource_None)
	{
		g_bMenuOpen[client] = false;
		g_bClimbersMenuOpen[client] = false;		
	}
	else
		return;

	//Timer Panel
	if (!g_bSayHook[client])
	{
		if (g_bTimeractivated[client])
		{
			if (g_bClimbersMenuOpen[client] == false)
				PlayerPanel(client);
		}
		
		//refresh ClimbersMenu when timer active
		if (g_bTimeractivated[client])
		{
			if (g_fCurrentRunTime[client] > g_fPersonalRecord[client] && !g_bMissedMapBest[client] && !g_bPause[client])
			{					
				decl String:szTime[32];
				g_bMissedMapBest[client]=true;
				FormatTimeFloat(client, g_fPersonalRecord[client], 3,szTime, sizeof(szTime));			
				if (g_fPersonalRecord[client] > 0.0)
					PrintToChat(client, "%t", "MissedMapBest", MOSSGREEN,WHITE,GRAY,DARKBLUE,szTime,GRAY);
				EmitSoundToClient(client,"buttons/button18.wav",client);
			}
			else
				if (g_fCurrentRunTime[client] > g_fPersonalRecordBonus[client] && g_bBonusTimer[client] && !g_bPause[client] && !g_bMissedBonusBest[client])
				{
					if (g_fPersonalRecordBonus[client] > 0.0) 
					{
						g_bMissedBonusBest[client] = true;
						decl String:szTime[32];
						FormatTimeFloat(client, g_fPersonalRecordBonus[client], 3, szTime, sizeof(szTime));
						PrintToChat(client, "[%cCK%c] %cYou have missed your best bonus time of (%c%s%c)", MOSSGREEN, WHITE, GRAY, YELLOW, szTime, GRAY);
						EmitSoundToClient(client, "buttons/button18.wav", client);
					}
				}
		}
	}
}

public NoClipCheck(client)
{
	decl MoveType:mt;
	mt = GetEntityMoveType(client); 
	if(!(g_bOnGround[client]))
	{	
		if (mt == MOVETYPE_NOCLIP)
			g_bNoClipUsed[client]=true;
	}
	if(mt == MOVETYPE_NOCLIP && (g_bTimeractivated[client]))
	{
		g_bTimeractivated[client] = false;
	}
}

public SpeedCap(client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return;
	static bool:IsOnGround[MAXPLAYERS + 1]; 
	if (g_bOnGround[client])
	{
		if (!IsOnGround[client])
		{
			IsOnGround[client] = true;    
			decl Float:CurVelVec[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", CurVelVec);
			if (GetVectorLength(CurVelVec) > 3500.0)
			{
				
				NormalizeVector(CurVelVec, CurVelVec);
				ScaleVector(CurVelVec, 3500.0);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
			}
		}
	}
	else
		IsOnGround[client] = false;	
}

public ButtonPressCheck(client, &buttons, Float: origin[3], Float:speed)
{
	if (IsValidClient(client) && !IsFakeClient(client) && g_LastButton[client] != IN_USE && buttons & IN_USE && ((g_fCurrentRunTime[client] > 0.1 || g_fCurrentRunTime[client] == -1.0)))
	{
		decl Float:diff; 
		diff = GetEngineTime() - g_fLastTimeButtonSound[client];
		if (diff > 0.1)
		{
			decl Float:dist; 
			dist=70.0;		
			decl  Float:distance1; 
			distance1 = GetVectorDistance(origin, g_fStartButtonPos);
			decl  Float: distance2;
			distance2 = GetVectorDistance(origin, g_fEndButtonPos);
			if (distance1 < dist && speed < 251.0 && !g_bFirstStartButtonPush)
			{
				new Handle:trace;
				trace = TR_TraceRayFilterEx(origin, g_fStartButtonPos, MASK_SOLID,RayType_EndPoint,TraceFilterPlayers,client);
				if (!TR_DidHit(trace))
				{
					CL_OnStartTimerPress(client);
					g_fLastTimeButtonSound[client] = GetEngineTime();	
				}
				CloseHandle(trace);								
			}
			else
				if (distance2 < dist  && !g_bFirstEndButtonPush)
				{
					new Handle:trace;
					trace = TR_TraceRayFilterEx(origin, g_fEndButtonPos, MASK_SOLID,RayType_EndPoint,TraceFilterPlayers,client);
					if (!TR_DidHit(trace))
					{
						CL_OnEndTimerPress(client);	
						g_fLastTimeButtonSound[client] = GetEngineTime();
					}
					CloseHandle(trace);		
				}
		}
	}		
	else
	{
		if (IsValidClient(client) && IsFakeClient(client) && g_bTimeractivated[client] && g_LastButton[client] != IN_USE && buttons & IN_USE)
		{
			new Float: distance = GetVectorDistance(origin, g_fEndButtonPos);	
			if (distance < 70.5  && !g_bFirstEndButtonPush)
			{
				new Handle:trace;
				trace = TR_TraceRayFilterEx(origin, g_fEndButtonPos, MASK_SOLID,RayType_EndPoint,TraceFilterPlayers,client);
				if (!TR_DidHit(trace))
				{
					CL_OnEndTimerPress(client);	
					g_fLastTimeButtonSound[client] = GetEngineTime();
				}
				CloseHandle(trace);		
			}			
		}
	}
}

public AutoBhopFunction(client,&buttons)
{
	if (!IsValidClient(client))
		return;
	if (g_bAutoBhop && g_bAutoBhopClient[client])
	{
		if (buttons & IN_JUMP)
			if (!(g_bOnGround[client]))
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
					if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
						buttons &= ~IN_JUMP;
						
	}
}

public SpecListMenuDead(client)
{
	decl String:szTick[32];
	Format(szTick, 32, "%i", g_Server_Tickrate);			
	decl ObservedUser;
	ObservedUser = -1;
	decl String:sSpecs[512];
	Format(sSpecs, 512, "");
	decl SpecMode;			
	ObservedUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");	
	SpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");	
	
	if (SpecMode == 4 || SpecMode == 5)
	{
		g_SpecTarget[client] = ObservedUser;
		decl count;
		count=0;
		//Speclist
		if (1 <= ObservedUser <= MaxClients)
		{
			decl x;
			decl String:szTime2[32];
			decl String:szProBest[32];	
			decl String:szPlayerRank[64];		
			Format(szPlayerRank,32,"");
			decl String:szStage[32];
			
			for(x = 1; x <= MaxClients; x++) 
			{					
				if (IsValidClient(x) && !IsFakeClient(client) && !IsPlayerAlive(x) && GetClientTeam(x) >= 1 && GetClientTeam(x) <= 3)
				{
				
					SpecMode = GetEntProp(x, Prop_Send, "m_iObserverMode");	
					if (SpecMode == 4 || SpecMode == 5)
					{				
						decl ObservedUser2;
						ObservedUser2 = GetEntPropEnt(x, Prop_Send, "m_hObserverTarget");
						if (ObservedUser == ObservedUser2)
						{
							count++;
							if (count < 6)
							Format(sSpecs, 512, "%s%N\n", sSpecs, x);									
						}	
						if (count ==6)
							Format(sSpecs, 512, "%s...", sSpecs);	
					}
				}					
			}
			
			//rank
			if (g_bPointSystem)
			{
				if (g_pr_points[ObservedUser] != 0)
				{
					decl String: szRank[32];
					if (g_PlayerRank[ObservedUser] > g_pr_RankedPlayers)
						Format(szRank,32,"-");
					else
						Format(szRank,32,"%i", g_PlayerRank[ObservedUser]);
					Format(szPlayerRank,32,"Rank: #%s/%i",szRank,g_pr_RankedPlayers);
				}
				else
					Format(szPlayerRank,32,"Rank: NA / %i",g_pr_RankedPlayers);
			}
			
			if (g_fPersonalRecord[ObservedUser] > 0.0)
			{
				FormatTimeFloat(client, g_fPersonalRecord[ObservedUser], 3, szTime2, sizeof(szTime2));
				Format(szProBest, 32, "%s (#%i/%i)", szTime2,g_MapRank[ObservedUser],g_MapTimesCount);		
			}
			else
				Format(szProBest, 32, "None");	

			if (g_mapZonesTypeCount[5]>0) //  There are stages
				Format(szStage, 32, "%i / %i", g_Stage[ObservedUser],(g_mapZonesTypeCount[5]+1));
			else
				Format(szStage, 32, "Linear map");

			if (g_Stage[ObservedUser] == 999) // if player is in stage 999
				Format(szStage, 32, "Bonus");

			if(!StrEqual(sSpecs,""))
			{
				decl String:szName[MAX_NAME_LENGTH];
				GetClientName(ObservedUser, szName, MAX_NAME_LENGTH);
				if (g_bTimeractivated[ObservedUser])
				{			
					decl String:szTime[32];
					decl Float:Time;
					Time = GetEngineTime() - g_fStartTime[ObservedUser] - g_fPauseTime[ObservedUser];								
					FormatTimeFloat(client, Time, 4, szTime, sizeof(szTime)); 			
					if (!g_bPause[ObservedUser])
					{
						if (!IsFakeClient(ObservedUser))
						{
							Format(g_szPlayerPanelText[client], 512, "Specs (%i):\n%s\n  \n%s\n%s\nRecord: %s\n\nStage: %s\n", count, sSpecs, szTime,szPlayerRank,szProBest,szStage);
							if (!g_bShowSpecs[client])
								Format(g_szPlayerPanelText[client], 512, "Specs (%i)\n \n%s\n%s\nRecord: %s\n\nStage: %s\n", count,szTime,szPlayerRank,szProBest,szStage);
						}
						else
						{	
							if (ObservedUser == g_RecordBot)
								Format(g_szPlayerPanelText[client], 512, "[Map Record Replay]\n%s\nTickrate: %s\nSpecs: %i\n\nStage: %s\n",szTime,szTick,count,szStage);
							else
								if (ObservedUser == g_BonusBot)
									Format(g_szPlayerPanelText[client], 512, "[Bonus Record Replay]\n%s\nTickrate: %s\nSpecs: %i\n\nStage: %s\n",szTime,szTick,count,szStage);

						}					
					}
					else
					{
						if (ObservedUser == g_RecordBot)
							Format(g_szPlayerPanelText[client], 512, "[Map Record Replay]\nTime: PAUSED\nTickrate: %s\nSpecs: %i\n\nStage: %s\n",szTick,count,szStage);
						else
							if (ObservedUser == g_BonusBot)
								Format(g_szPlayerPanelText[client], 512, "[Bonus Record Replay]\nTime: PAUSED\nTickrate: %s\nSpecs: %i\n\nStage: Bonus\n",szTick,count);
					}
				}
				else
				{
					if (ObservedUser != g_RecordBot) 
					{
						Format(g_szPlayerPanelText[client], 512, "%Specs (%i):\n%s\n \n%s\nRecord: %s\n", count, sSpecs,szPlayerRank, szProBest);
						if (!g_bShowSpecs[client])
							Format(g_szPlayerPanelText[client], 512, "Specs (%i)\n \n%s\nRecord: %s\n", count,szPlayerRank,szProBest);						
					}
				}
			
				if (!g_bShowTime[client] && g_bShowSpecs[client])
				{
					if (ObservedUser != g_RecordBot && ObservedUser != g_BonusBot) 
						Format(g_szPlayerPanelText[client], 512,  "%Specs (%i):\n%s\n \n%s\nRecord: %s\n\nStage: %s\n", count, sSpecs,szPlayerRank, szProBest, szStage);
					else
					{
						if (ObservedUser == g_RecordBot)
							Format(g_szPlayerPanelText[client], 512, "Record replay of\n%s\n \nTickrate: %s\nSpecs (%i):\n%s\n\nStage: %s\n", g_szReplayName,szTick, count, sSpecs,szStage);	
						else
							if (ObservedUser == g_BonusBot)
								Format(g_szPlayerPanelText[client], 512, "Bonus replay of\n%s\n \nTickrate: %s\nSpecs (%i):\n%s\n\nStage: Bonus\n", g_szBonusName,szTick, count, sSpecs);	

					}	
				}
				if (!g_bShowTime[client] && !g_bShowSpecs[client])
				{
					if (ObservedUser != g_RecordBot) 
						Format(g_szPlayerPanelText[client], 512, "%s\nRecord: %s\n\nStage: %s\n", szPlayerRank,szProBest,szStage);	
					else
					{
						if (ObservedUser == g_RecordBot)
							Format(g_szPlayerPanelText[client], 512, "Record replay of\n%s\n \nTickrate: %s\n\nStage: %s\n", g_szReplayName,szTick,szStage);	
						else
							if (ObservedUser == g_BonusBot)
								Format(g_szPlayerPanelText[client], 512, "Bonus replay of\n%s\n \nTickrate: %s\n\nStage: Bonus\n", g_szBonusName,szTick,szStage);	

					}	
				}
				g_bClimbersMenuOpen[client] = false;	
				
				SpecList(client);
			}
		}	
	}	
	else
		g_SpecTarget[client] = -1;
}

public SpecListMenuAlive(client)
{

	if (IsFakeClient(client))
		return;
	
	if (g_bMenuOpen[client])
		return;
		
	//Spec list for players
	Format(g_szPlayerPanelText[client], 512, "");
	decl String:sSpecs[512];
	decl SpecMode;
	Format(sSpecs, 512, "");
	decl count;
	count=0;
	for(new i = 1; i <= MaxClients; i++) 
	{
		if (IsValidClient(i) && !IsFakeClient(client) && !IsPlayerAlive(i) && !g_bFirstTeamJoin[i] && g_bSpectate[i])
		{			
			SpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if (SpecMode == 4 || SpecMode == 5)
			{		
				decl Target;
				Target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");	
				if (Target == client)
				{
					count++;
					if (count < 6)
					Format(sSpecs, 512, "%s%N\n", sSpecs, i);

				}	
				if (count == 6)
					Format(sSpecs, 512, "%s...", sSpecs);
			}					
		}		
	}	
	if (count > 0)
	{
		if (g_bShowSpecs[client])
			Format(g_szPlayerPanelText[client], 512, "Specs (%i):\n%s ", count, sSpecs);
		else
			Format(g_szPlayerPanelText[client], 512, "Specs (%i)\n ", count);
		SpecList(client);
	}
	else
		Format(g_szPlayerPanelText[client], 512, "");	
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
GetPos(client,arg) 
{
	decl Float:origin[3],Float:angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	new Handle:trace = TR_TraceRayFilterEx(origin,angles,MASK_SHOT,RayType_Infinite,TraceFilterPlayers,client);
	if(!TR_DidHit(trace)) 
	{
		CloseHandle(trace);
		PrintToChat(client, "%t", "Measure3",MOSSGREEN,WHITE);
		return;
	}
	TR_GetEndPosition(origin,trace);
	CloseHandle(trace);
	g_fvMeasurePos[client][arg][0] = origin[0];
	g_fvMeasurePos[client][arg][1] = origin[1];
	g_fvMeasurePos[client][arg][2] = origin[2];
	PrintToChat(client, "%t", "Measure4",MOSSGREEN,WHITE,arg+1,origin[0],origin[1],origin[2]);	
	if(arg == 0) 
	{
		if(g_hP2PRed[client] != INVALID_HANDLE) 
		{
			CloseHandle(g_hP2PRed[client]);
			g_hP2PRed[client] = INVALID_HANDLE;
		}
		g_bMeasurePosSet[client][0] = true;
		g_hP2PRed[client] = CreateTimer(1.0,Timer_P2PRed,client,TIMER_REPEAT);
		P2PXBeam(client,0);
	}
	else 
	{
		if(g_hP2PGreen[client] != INVALID_HANDLE) 
		{
			CloseHandle(g_hP2PGreen[client]);
			g_hP2PGreen[client] = INVALID_HANDLE;
		}
		g_bMeasurePosSet[client][1] = true;
		P2PXBeam(client,1);
		g_hP2PGreen[client] = CreateTimer(1.0,Timer_P2PGreen,client,TIMER_REPEAT);
	}
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
public Action:Timer_P2PRed(Handle:timer,any:client) 
{
	P2PXBeam(client,0);
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
public Action:Timer_P2PGreen(Handle:timer,any:client) 
{
	P2PXBeam(client,1);
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
P2PXBeam(client,arg) 
{
	decl Float:Origin0[3],Float:Origin1[3],Float:Origin2[3],Float:Origin3[3];
	Origin0[0] = (g_fvMeasurePos[client][arg][0] + 8.0);
	Origin0[1] = (g_fvMeasurePos[client][arg][1] + 8.0);
	Origin0[2] = g_fvMeasurePos[client][arg][2];	
	Origin1[0] = (g_fvMeasurePos[client][arg][0] - 8.0);
	Origin1[1] = (g_fvMeasurePos[client][arg][1] - 8.0);
	Origin1[2] = g_fvMeasurePos[client][arg][2];	
	Origin2[0] = (g_fvMeasurePos[client][arg][0] + 8.0);
	Origin2[1] = (g_fvMeasurePos[client][arg][1] - 8.0);
	Origin2[2] = g_fvMeasurePos[client][arg][2];	
	Origin3[0] = (g_fvMeasurePos[client][arg][0] - 8.0);
	Origin3[1] = (g_fvMeasurePos[client][arg][1] + 8.0);
	Origin3[2] = g_fvMeasurePos[client][arg][2];	
	if(arg == 0) 
	{
		Beam(client,Origin0,Origin1,0.97,2.0,255,0,0);
		Beam(client,Origin2,Origin3,0.97,2.0,255,0,0);
	}
	else 
	{
		Beam(client,Origin0,Origin1,0.97,2.0,0,255,0);
		Beam(client,Origin2,Origin3,0.97,2.0,0,255,0);
	}
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
Beam(client,Float:vecStart[3],Float:vecEnd[3],Float:life,Float:width,r,g,b) 
{
	TE_Start("BeamPoints");
	TE_WriteNum("m_nModelIndex",g_Beam[2]);
	TE_WriteNum("m_nHaloIndex",0);
	TE_WriteNum("m_nStartFrame",0);
	TE_WriteNum("m_nFrameRate",0);
	TE_WriteFloat("m_fLife",life);
	TE_WriteFloat("m_fWidth",width);
	TE_WriteFloat("m_fEndWidth",width);
	TE_WriteNum("m_nFadeLength",0);
	TE_WriteFloat("m_fAmplitude",0.0);
	TE_WriteNum("m_nSpeed",0);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("a",255);
	TE_WriteNum("m_nFlags",0);
	TE_WriteVector("m_vecStartPoint",vecStart);
	TE_WriteVector("m_vecEndPoint",vecEnd);
	TE_SendToClient(client);
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
ResetPos(client) 
{
	if(g_hP2PRed[client] != INVALID_HANDLE) 
	{
		CloseHandle(g_hP2PRed[client]);
		g_hP2PRed[client] = INVALID_HANDLE;
	}
	if(g_hP2PGreen[client] != INVALID_HANDLE) 
	{
		CloseHandle(g_hP2PGreen[client]);
		g_hP2PGreen[client] = INVALID_HANDLE;
	}
	g_bMeasurePosSet[client][0] = false;
	g_bMeasurePosSet[client][1] = false;

	g_fvMeasurePos[client][0][0] = 0.0; //This is stupid.
	g_fvMeasurePos[client][0][1] = 0.0;
	g_fvMeasurePos[client][0][2] = 0.0;
	g_fvMeasurePos[client][1][0] = 0.0;
	g_fvMeasurePos[client][1][1] = 0.0;
	g_fvMeasurePos[client][1][2] = 0.0;
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
public bool:TraceFilterPlayers(entity,contentsMask) 
{
	return (entity > MaxClients) ? true : false;
} //Thanks petsku

//jsfunction.inc
stock GetGroundOrigin(client, Float:pos[3])
{
	decl Float:fOrigin[3], Float:result[3];
	GetClientAbsOrigin(client, fOrigin);
	TraceClientGroundOrigin(client, result, 100.0);
	pos = fOrigin;
	pos[2] = result[2];
}

//jsfunction.inc
stock TraceClientGroundOrigin(client, Float:result[3], Float:offset)
{
	decl Float:temp[2][3];
	GetClientEyePosition(client, temp[0]);
	temp[1] = temp[0];
	temp[1][2] -= offset;
	new Float:mins[] ={-16.0, -16.0, 0.0};
	new Float:maxs[] =	{16.0, 16.0, 60.0};
	new Handle:trace = TR_TraceHullFilterEx(temp[0], temp[1], mins, maxs, MASK_SHOT, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}

//jsfunction.inc
public bool:TraceEntityFilterPlayer(entity, contentsMask) 
{
    return entity > MaxClients;
}

public CreateNavFiles()
{
	decl String:DestFile[256];
	decl String:SourceFile[256];
	Format(SourceFile, sizeof(SourceFile), "maps/replay_bot.nav");
	if (!FileExists(SourceFile))
	{
		LogError("<ckSurf> Failed to create .nav files. Reason: %s doesn't exist!", SourceFile);
		return;
	}
	decl String:map[256];
	new mapListSerial = -1;
	if (ReadMapList(g_MapList,	mapListSerial, "mapcyclefile", MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT) == INVALID_HANDLE)
		if (mapListSerial == -1)
			return;

	for (new i = 0; i < GetArraySize(g_MapList); i++)
	{
		GetArrayString(g_MapList, i, map, sizeof(map));
		if (!StrEqual(map, "", false))
		{
			Format(DestFile, sizeof(DestFile), "maps/%s.nav", map);
			if (!FileExists(DestFile))
				File_Copy(SourceFile, DestFile);
		}
	}	
}

public LoadInfoBot()
{
	if (!g_bInfoBot)
		return;

	g_InfoBot = -1;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || !IsFakeClient(i) || i == g_RecordBot || i == g_BonusBot)
			continue;
		g_InfoBot = i;
		break;
	}
	if(IsValidClient(g_InfoBot))
	{	
		Format(g_pr_rankname[g_InfoBot], 16, "BOT");
		CS_SetClientClanTag(g_InfoBot, "");
		SetEntProp(g_InfoBot, Prop_Send, "m_iAddonBits", 0);
		SetEntProp(g_InfoBot, Prop_Send, "m_iPrimaryAddon", 0);
		SetEntProp(g_InfoBot, Prop_Send, "m_iSecondaryAddon", 0); 		
		SetEntProp(g_InfoBot, Prop_Send, "m_iObserverMode", 1);
		SetInfoBotName(g_InfoBot);	
	}
	else
	{
		new count = 0;
		if (g_bMapReplay)
			count++;
		if (g_bInfoBot)
			count++;
		if (count==0)
			return;
		decl String:szBuffer2[64];
		Format(szBuffer2, sizeof(szBuffer2), "bot_quota %i", count); 	
		ServerCommand(szBuffer2);		
		CreateTimer(0.5, RefreshInfoBot,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RefreshInfoBot(Handle:timer)
{
	LoadInfoBot();
}
	
	
public SetInfoBotName(ent)
{
	decl String:szBuffer[64];
	decl String:sNextMap[128];	
	if (!IsValidClient(g_InfoBot) || !g_bInfoBot)
		return;
	if(g_bMapChooser && EndOfMapVoteEnabled() && !HasEndOfMapVoteFinished())
		Format(sNextMap, sizeof(sNextMap), "Pending Vote");
	else
	{
		GetNextMap(sNextMap, sizeof(sNextMap));
		new String:mapPieces[6][128];
		new lastPiece = ExplodeString(sNextMap, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
		Format(sNextMap, sizeof(sNextMap), "%s", mapPieces[lastPiece-1]); 			
	}			
	new timeleft;
	GetMapTimeLeft(timeleft);
	new Float:ftime = float(timeleft);
	decl String:szTime[32];
	FormatTimeFloat(g_InfoBot,ftime,4,szTime,sizeof(szTime));
	new Handle:hTmp;	
	hTmp = FindConVar("mp_timelimit");
	new iTimeLimit = GetConVarInt(hTmp);			
	if (hTmp != INVALID_HANDLE)
		CloseHandle(hTmp);	
	if (g_bMapEnd && iTimeLimit > 0)
		Format(szBuffer, sizeof(szBuffer), "%s (in %s)",sNextMap, szTime);
	else
		Format(szBuffer, sizeof(szBuffer), "Pending Vote (no time limit)");
	CS_SetClientName(g_InfoBot, szBuffer);
	Client_SetScore(g_InfoBot,9999);
	CS_SetClientClanTag(g_InfoBot, "NEXTMAP");
}

public CenterHudDead(client)
{
	decl String:szTick[32];
	Format(szTick, 32, "%i", g_Server_Tickrate);			
	decl ObservedUser; 
	ObservedUser= -1;
	decl SpecMode;			
	ObservedUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");	
	SpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");	
	if (SpecMode == 4 || SpecMode == 5)
	{
		g_SpecTarget[client] = ObservedUser;
		//keys
		decl String:sResult[256];	
		decl Buttons;
		if (g_bInfoPanel[client] && IsValidClient(ObservedUser))
		{
			Buttons = g_LastButton[ObservedUser];					
			if (Buttons & IN_MOVELEFT)
				Format(sResult, sizeof(sResult), "<font color='#00CC00'>A</font>");
			else
				Format(sResult, sizeof(sResult), "_");
			if (Buttons & IN_FORWARD)
				Format(sResult, sizeof(sResult), "%s <font color='#00CC00'>W</font>", sResult);
			else
				Format(sResult, sizeof(sResult), "%s _", sResult);	
			if (Buttons & IN_BACK)
				Format(sResult, sizeof(sResult), "%s <font color='#00CC00'>S</font>", sResult);
			else
				Format(sResult, sizeof(sResult), "%s _", sResult);	
			if (Buttons & IN_MOVERIGHT)
				Format(sResult, sizeof(sResult), "%s <font color='#00CC00'>D</font>", sResult);
			else
				Format(sResult, sizeof(sResult), "%s _", sResult);	
			if (Buttons & IN_DUCK)
				Format(sResult, sizeof(sResult), "%s - <font color='#00CC00'>DUCK</font>", sResult);
			else
				Format(sResult, sizeof(sResult), "%s - _", sResult);			
			if (Buttons & IN_JUMP)
				Format(sResult, sizeof(sResult), "%s <font color='#00CC00'>JUMP</font>", sResult);
			else
				Format(sResult, sizeof(sResult), "%s _", sResult);	
			
			if (g_bTimeractivated[ObservedUser]) {
				obsTimer = GetEngineTime() - g_fStartTime[ObservedUser] - g_fPauseTime[ObservedUser];								
				FormatTimeFloat(client, obsTimer, 3, obsAika, sizeof(obsAika));
			} else {
				obsAika = "<font color='#FF0000'>Stopped</font>";
			}
			PrintHintText(client,"<font face=''><font color='#75D1FF'>Timer:</font> %s\n<font color='#75D1FF'>Speed:</font> %.1f u/s\n%s",obsAika,g_fLastSpeed[ObservedUser],sResult);
		}			
	}	
	else
		g_SpecTarget[client] = -1;
}

public CenterHudAlive(client)
{
	if (!IsValidClient(client))
		return;
	
	//menu check
	if (!g_bTimeractivated[client])
	{
		PlayerPanel(client);			
	}

	if (g_bInfoPanel[client])
	{
		if (g_mapZonesTypeCount[5] == 0) // map is linear
		{
			if (g_Stage[client] == 999)
				g_StageString[client] = "Bonus\t"; // in bonus
			else
				g_StageString[client] = "Linear\t";
		}
		else if (g_Stage[client] == 999) // map has stages
			g_StageString[client] = "Bonus\t"; // in bonus
		else 
		{
			if (g_Stage[client]>9)
				Format(g_StageString[client], 24, "%s / %s\t", g_szCurrentStage[client], g_szTotalStages); // less \t's to make lines align
			else
				Format(g_StageString[client], 24, "%s / %s\t\t", g_szCurrentStage[client], g_szTotalStages);
		}

		if (g_Stage[client] == 999) // if in bonus stage, get bonus times
		{
			if (g_fPersonalRecordBonus[client]>0.0)
				Format(g_szRecordString[client], 32, "%s \tRank: %i / %i", g_szPersonalRecordBonus[client], g_MapRankBonus[client], g_iBonusCount);
			else
				if (g_iBonusCount>0)
					Format(g_szPersonalRecordBonus[client], 32, "N/A \t\tRank: N/A / %i", g_iBonusCount);
				else
					Format(g_szPersonalRecordBonus[client], 32, "N/A \t\tRank: N/A");

		}
		else // if in normal map, get normal times
		{
			if (g_fPersonalRecord[client] > 0.0) 
				Format(g_szRecordString[client], 32, "%s \tRank: %i / %i",g_szPersonalRecord[client],g_MapRank[client],g_MapTimesCount);
			else
				if (g_MapTimesCount>0)
					Format(g_szRecordString[client], 32, "N/A \t\tRank: N/A / %i", g_MapTimesCount);
				else
					Format(g_szRecordString[client], 32, "N/A \t\tRank: N/A");
		}
		if (g_bTimeractivated[client] && !g_bPause[client]) 
		{
			GetcurrentRunTime(client);
			FormatTimeFloat(client, g_fCurrentRunTime[client], 3, pAika[client], 128);
			if (g_bMissedMapBest[client] && g_fPersonalRecord[client] > 0.0) // missed best personal time
			{
				Format(pAika[client], 128, "<font color='#FFFFB2'>%s</font>", pAika[client]);
			}
			else if (g_fPersonalRecord[client] < 0.1) // hasn't finished the map yet
			{
				Format(pAika[client], 128, "<font color='#7F7FFF'>%s</font>", pAika[client]);
			}
			else
			{
				Format(pAika[client], 128, "<font color='#99FF99'>%s</font>", pAika[client]); // hasn't missed best personal time yet
			}
		}
		if (IsValidEntity(client) && 1 <= client <= MaxClients && !g_bOverlay[client])
		{
			if (g_bTimeractivated[client]) {
				if (g_bPause[client]) {
					PrintHintText(client,"<font face=''>Timer: <font color='#FF0000'>Paused</font>\nRecord: %s\nStage: %sSpeed: %i</font>", g_szRecordString[client], g_StageString[client], RoundToNearest(g_fLastSpeed[client]));			
				} else if (!g_bBonusTimer[client])
				{
					PrintHintText(client,"<font face=''>Timer: %s\nRecord: %s\nStage: %sSpeed: %i</font>",pAika[client], g_szRecordString[client], g_StageString[client], RoundToNearest(g_fLastSpeed[client]));			
				} else
				{
					PrintHintText(client,"<font face=''>Bonus Timer: %s\nRecord: %s\nStage: %sSpeed: %i</font>",pAika[client], g_szPersonalRecordBonus[client], g_StageString[client], RoundToNearest(g_fLastSpeed[client]));			
				}
			} else {
				PrintHintText(client,"<font face=''>Timer: <font color='#FF0000'>Stopped</font>\nRecord: %s\nStage: %sSpeed: %i</font>", g_szRecordString[client], g_StageString[client], RoundToNearest(g_fLastSpeed[client]));			
			}
		}
	}	
}

public Checkpoint(client, zone)
{
	if (!IsValidClient(client) || g_bPositionRestored[client])
		return;

	if (zone > 19)
	{
		LogError("Maximum number of checkpoints reached! (20)");
		return;
	}
	
	GetcurrentRunTime(client);
	new Float:time = g_fCurrentRunTime[client];
	new Float:total = 0.0;
	new totalPoints = 0;
	new Float:percent = -1.0;
	new String:szPercnt[24];
	for (new i = 0; i < 20; i++)
		total = total + g_fCheckpointTimesRecord[client][i];

	if (g_mapZonesTypeCount[5]>0)
		totalPoints = g_mapZonesTypeCount[5];
	else
		if (g_mapZonesTypeCount[6]>0)
			totalPoints = g_mapZonesTypeCount[6];

	// Count percent of completion
	percent = (float(zone+1)/float(totalPoints+1));
	percent = percent*100.0;
	Format(szPercnt, 24, "%1.f%%", percent);

	if (g_bTimeractivated[client]) {
		if (g_fMaxPercCompleted[client] < 1.0) // First time a checkpoint is reached
			g_fMaxPercCompleted[client] = percent;
		else
			if (g_fMaxPercCompleted[client] < percent) // The furthest checkpoint reached
				g_fMaxPercCompleted[client] = percent;
	}

	g_fCheckpointTimesNew[client][zone] = time;



	if (total > 1.0 && g_bTimeractivated[client])
	{
		// Set percent of completion to assist
		if (CS_GetMVPCount(client) < 1)
			CS_SetClientAssists(client, RoundToFloor(g_fMaxPercCompleted[client]));
		else
			CS_SetClientAssists(client, 100);

		new Float:diff;
		new Float:catchUp;
		new String:szDiff[32];
		new String:szCatchUp[32];

		diff = (g_fCheckpointTimesRecord[client][zone] - time);
		FormatTimeFloat(client, diff, 5, szDiff, 32);
		if (tmpDiff[client] == 9999.0)
		{
			if (diff > 0)
			{
				Format(szDiff, sizeof(szDiff), "-%s", szDiff);
				PrintToChat(client, "%t", "Checkpoint1", MOSSGREEN,WHITE,YELLOW,GREEN,szDiff,YELLOW,WHITE,szPercnt,YELLOW);
			}	
			else
			{
				Format(szDiff, sizeof(szDiff), "+%s", szDiff);
				PrintToChat(client, "%t", "Checkpoint1", MOSSGREEN,WHITE,YELLOW,RED,szDiff,YELLOW,WHITE,szPercnt,YELLOW);
			}
		}
		else
		{
			catchUp = diff - tmpDiff[client];
			FormatTimeFloat(client, catchUp, 5, szCatchUp, 32);
			if (diff > 0)
			{
				Format(szDiff, sizeof(szDiff), "-%s", szDiff);
				if (catchUp > 0){
					Format(szCatchUp, sizeof(szCatchUp), "-%s", szCatchUp);
					//	"en"		"[{1}CK{2}] {3}CP: {4}{5} {6}compared to your PB. Grew lead by: {7}{8} {9}({10}{11}{12})"
					PrintToChat(client, "%t", "Checkpoint2",MOSSGREEN,WHITE,YELLOW,GREEN,szDiff,YELLOW,GREEN,szCatchUp,YELLOW,WHITE,szPercnt,YELLOW);
				}
				else
				{
					Format(szCatchUp, sizeof(szCatchUp), "+%s", szCatchUp);
					PrintToChat(client, "%t", "Checkpoint3",MOSSGREEN,WHITE,YELLOW,GREEN,szDiff,YELLOW,RED,szCatchUp,YELLOW,WHITE,szPercnt,YELLOW);
				}
			}	
			else
			{
				Format(szDiff, sizeof(szDiff), "+%s", szDiff);
				if (catchUp > 0){
					Format(szCatchUp, sizeof(szCatchUp), "-%s", szCatchUp);
//							"#format"	"{1:c},{2:c},{3:c},{4:c},{5:s},{6:c},{7:c},{8:s},{9:c},{10:c},{11:s},{12:c}"
					PrintToChat(client, "%t", "Checkpoint4",MOSSGREEN,WHITE,YELLOW,RED,szDiff,YELLOW,GREEN,szCatchUp,YELLOW,WHITE,szPercnt,YELLOW);
				}
				else
				{
					//		"#format"	"{1:c},{2:c},{3:c},{4:c},{5:s},{6:c},{7:c},{8:s},{9:c},{10:c},{11:s},{12:c}"

					Format(szCatchUp, sizeof(szCatchUp), "+%s", szCatchUp);
					PrintToChat(client, "%t", "Checkpoint5",MOSSGREEN,WHITE,YELLOW,RED,szDiff,YELLOW,RED,szCatchUp,YELLOW,WHITE,szPercnt,YELLOW);
				}
			}	
		}
		tmpDiff[client] = diff;	
	}
	else  // if first run 
		if (g_bTimeractivated[client])
		{
			// Set percent of completion to assist
			if (CS_GetMVPCount(client) < 1)
				CS_SetClientAssists(client, RoundToFloor(g_fMaxPercCompleted[client]));
			else
				CS_SetClientAssists(client, 100);
				
			new String:szTime[32];
			FormatTimeFloat(client, time, 3, szTime, 32);

			if (percent > -1.0)
				PrintToChat(client, "[%cCK%c]%c CP: Completed%c %s %cof the map in%c %s", MOSSGREEN,WHITE,YELLOW,WHITE,szPercnt,YELLOW,WHITE,szTime);

		}
		else
			PrintToChat(client, "[%cCK%c]%c CP: Reached checkpoint%c %i", MOSSGREEN,WHITE,YELLOW,WHITE,(1+zone));
}

