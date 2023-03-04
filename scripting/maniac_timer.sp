#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

ConVar mp_freezetime;
StringMap map;
Handle HTimer;
Event g_hEvent;
static int ctime;
int g_iTime;

public Plugin myinfo = 
{
	name = "Maniac Timer",
	author = "Pisex",
	version = "1.2",
	url = "Всё проплачено(source-project.ru)"
}

public void OnPluginStart()
{
	mp_freezetime = FindConVar("mp_freezetime");
	HookEvent("round_start",OnRoundStart,EventHookMode_PostNoCopy);
	HookEvent("round_end",OnRoundEnd);
	LoadCFG();
}

public void OnMapStart()
{
	g_hEvent = CreateEvent("show_survival_respawn_status", true);
	char mapcopy[64];
	GetCurrentMap(mapcopy,sizeof mapcopy);
	GetMapDisplayName(mapcopy,mapcopy,sizeof mapcopy);
	map.GetValue(mapcopy,g_iTime);
}

public void OnMapEnd()
{
	g_hEvent.Cancel();
}

void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (GameRules_GetProp("m_bWarmupPeriod")) 
		return;
	HTimer = CreateTimer(1.0, TimerCountDown, RoundFloat(mp_freezetime.FloatValue) + g_iTime,TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(HTimer)
	{
		KillTimer(HTimer);
		HTimer = null;
		delete HTimer;
		ctime = 0;
	}
}

Action TimerCountDown(Handle timer, int time)
{
	if (!ctime)
	{
		ctime = time;
	}

	ctime--;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (ctime < 1)
			{
				AlertText(g_hEvent, i, 3, "Маньяк вышел на охоту!");
			}
			else
			{
				AlertText(g_hEvent, i, 2, "Маньяк выйдет на охоту через <font color='#FF0000'>%d</font> сек.", ctime);
			}
		}
	}

	if (ctime < 1)
	{
		timer = null;
		delete timer;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void AlertText(Event event, int client, int duration, const char[] msg, any ...)
{
    static char buff[512];
    VFormat(buff, sizeof(buff), msg, 5);
    event.SetString("loc_token", buff);
    event.SetInt("duration", duration);
    event.SetInt("userid", -1);
    event.FireToClient(client);
}

void LoadCFG()
{
	KeyValues kv = new KeyValues("Maniac Timer");
	char buff[256];
	BuildPath(Path_SM, buff, sizeof buff, "configs/maniac_timer.cfg");
	if(!kv.ImportFromFile(buff))
	{
		SetFailState("Файл(%s) конфигурации не найден!",buff);
	}
	if(kv.GotoFirstSubKey(false))
	{
		delete map;
		map = new StringMap();
		do
		{
			if(kv.GetSectionName(buff,sizeof buff))
			{
				map.SetValue(buff,kv.GetNum(NULL_STRING));
			}
		}
		while(kv.GotoNextKey(false));
	}
	delete kv;
}