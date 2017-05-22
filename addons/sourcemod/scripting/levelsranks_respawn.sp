#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"

int		g_iRespawnCount,
		g_iRespawnLevel[64],
		g_iRespawnNumber[64],
		g_iRank[MAXPLAYERS+1],
		g_iRespawns[MAXPLAYERS+1];

public Plugin myinfo = {name = "[LR] Module - Respawn", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS: LogMessage("[%s Respawn] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Respawn] Плагин работает только на CS:GO и CS:S", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LR_ModuleCount();
	HookEvent("round_start", RoundStart);
	LoadTranslations("levels_ranks_respawn.phrases");
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/respawn.ini");
	KeyValues hLR_Respawn = new KeyValues("LR_Respawn");

	if(!hLR_Respawn.ImportFromFile(sPath) || !hLR_Respawn.GotoFirstSubKey())
	{
		SetFailState("[%s Respawn] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_Respawn.Rewind();

	if(hLR_Respawn.JumpToKey("Settings"))
	{
		g_iRespawnCount = 0;
		hLR_Respawn.GotoFirstSubKey();

		do
		{
			g_iRespawnNumber[g_iRespawnCount] = hLR_Respawn.GetNum("count", 1);
			g_iRespawnLevel[g_iRespawnCount] = hLR_Respawn.GetNum("rank", 0);
			g_iRespawnCount++;
		}
		while(hLR_Respawn.GotoNextKey());
	}
	else SetFailState("[%s Respawn] : фатальная ошибка - секция Settings не найдена", PLUGIN_NAME);
	delete hLR_Respawn;
}

public void RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	for(int id = 1; id <= MaxClients; id++)
	{
		if(IsValidClient(id))
		{
			g_iRespawns[id] = 0;
			g_iRank[id] = LR_GetClientRank(id);

			for(int i = g_iRespawnCount - 1; i >= 0; i--)
			{
				if(g_iRank[id] >= g_iRespawnLevel[i])
				{
					g_iRespawns[id] = g_iRespawnNumber[i];
					break;
				}
			}
		}
	}
}

public void LR_OnMenuCreated(int iClient, int iRank, Menu& hMenu)
{
	if(iRank == 0)
	{
		char sText[64];
		SetGlobalTransTarget(iClient);
		FormatEx(sText, sizeof(sText), "%t (%i)", "Respawn", g_iRespawns[iClient]);
		hMenu.AddItem("Respawn", sText, (g_iRespawns[iClient] > 0 && !IsPlayerAlive(iClient)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
}

public void LR_OnMenuItemSelected(int iClient, int iRank, const char[] sInfo)
{
	if(iRank == 0)
	{
		if(strcmp(sInfo, "Respawn") == 0)
		{
			CS_RespawnPlayer(iClient);
			g_iRespawns[iClient]--;
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	g_iRank[iClient] = 0;
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);
		}
	}
}