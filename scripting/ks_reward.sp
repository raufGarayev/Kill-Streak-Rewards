#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>

KeyValues
	kvRevards;
int
	iMode,
	iFrags[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name		= "Kill Streak Rewards",
	version		= "1.1.0 (rewritten by Grey83)",
	description	= "Give weapons/equipments for kills",
	author		= "GARAYEV",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_ksr_reload", Cmd_Reload, ADMFLAG_CONFIG, "Reload plugin config");

	HookEvent("player_death", Event_Player);
	HookEvent("player_spawn", Event_Player);
}

public Action Cmd_Reload(int client, int args)
{
	ReloadCfg(client);
	return Plugin_Handled;
}

public void OnMapStart()
{
	ReloadCfg();
}

stock void ReloadCfg(const int client = 0)
{
	iMode = iFrags[0] = 0;
	if(kvRevards) delete kvRevards;
	kvRevards = new KeyValues("Rewards");

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/ks_rewards.ini");
	if(!kvRevards.ImportFromFile(buffer))
		Format(buffer, sizeof(buffer), "[Kill Streak Rewards] Could not locate config '%s'", buffer);
	else if(!kvRevards.GotoFirstSubKey(false))
		Format(buffer, sizeof(buffer), "[Kill Streak Rewards] Config '%s' is empty", buffer);
	else
	{
		iMode = kvRevards.GetNum(NULL_STRING);
		ReplyToCommand(client, "Mode: %i", iMode);

		int num, frags;
		while(kvRevards.GotoNextKey(false))
		{
			kvRevards.GetSectionName(buffer, sizeof(buffer));
			ReplyToCommand(client, "Section: %s", buffer);
			if((frags = StringToInt(buffer)) < 1) continue;

			kvRevards.GetString(NULL_STRING, buffer, sizeof(buffer));
			ReplyToCommand(client, "Value: %s", buffer);
			if(!buffer[0]) continue;

			num++;
			if(frags > iFrags[0]) iFrags[0] = frags;
		}

		if(!iFrags[0]) FormatEx(buffer, sizeof(buffer), "[Kill Streak Rewards] Config haven't valid values");
		else
		{
			ReplyToCommand(client, "[Kill Streak Rewards] Successfully loaded config. Mode: %s Max streak: %i Rewards: %i", !iMode ? "off" : iMode == 2 ? "normal" : "ffa", iFrags[0], num);
			return;
		}
	}
	delete kvRevards;
	if(!client) LogError(buffer);
	else ReplyToCommand(client, buffer);
}

public void OnClientPostAdminCheck(int client)
{
	iFrags[client] = 0;
}

public void Event_Player(Event event, const char[] name, bool dontBroadcast)
{
	if(!iMode || !kvRevards)
		return;

	int victim, client;
	if(!(victim = GetClientId(event.GetInt("userid"))))
		return;

	if(!IsFakeClient(victim)) iFrags[victim] = 0;
	if(name[7] == 's')
		return;

	if((client = GetClientId(event.GetInt("attacker"))) && !IsFakeClient(client) && IsPlayerAlive(client)
	&& (iMode == 1 || GetClientTeam(client) != GetClientTeam(victim)))
	{
		static char buffer[32];
		FormatEx(buffer, sizeof(buffer), "%i", ++iFrags[client]);
		kvRevards.Rewind();
		kvRevards.GetString(buffer, buffer, sizeof(buffer));
		if(!buffer[0])
			return;

		if(GivePlayerItem(client, buffer) == -1) LogError("[Kill Streak Rewards] Unable to give '%s' to player", buffer);
		if(iFrags[client] == iFrags[0]) iFrags[client] = 0;
	}
}

stock int GetClientId(const int uid)
{
	static int id;
	return (id = GetClientOfUserId(uid)) && IsClientInGame(id) ? id : 0;
}
