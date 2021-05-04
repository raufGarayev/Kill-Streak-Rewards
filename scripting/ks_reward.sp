#include <sourcemod>
#include <sdktools>
#pragma newdecls required

int i_KillCount[MAXPLAYERS+1];
ConVar ksreward_enabled;
ConVar ksreward_kills;

stock const char g_szReward[] = "ks_reward";

char g_szAward[256];

public Plugin myinfo = 
{
    name =            "Kill Streak Rewards",
    author =          "GARAYEV",
    description =     "Give weapons/equipments for kills",
    version =         "1.0.0",
    url =             "https://progaming.ba"
};

public void OnPluginStart()
{
    ksreward_enabled = CreateConVar("ksreward_enabled", "1", "Enable = 1 | Disable = 0", _, true, 0.0, true, 1.0);
    ksreward_kills = CreateConVar("ksreward_kills", "3", "How many kills client must get to receive reward");
    HookConVarChange(CreateConVar(g_szReward, "weapon_healthshot", "Reward to give"), OnRewardChanged);

    AutoExecConfig(true, "ks_reward");
    
    HookEvent("player_death", Hook_PlayerDeath);
}

public void OnConfigsExecuted() {
    OnRewardChanged(FindConVar(g_szReward), NULL_STRING, NULL_STRING);
}

public void OnRewardChanged(Handle hCvar, const char[] szOld, const char[] szNew)
{
        GetConVarString(hCvar, g_szAward, sizeof(g_szAward));
}

public void OnClientPostAdminCheck(int client)
{
    i_KillCount[client] = 0;
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(!ksreward_enabled.BoolValue) return Plugin_Continue;
    
    int Attacker = GetClientOfUserId(event.GetInt("attacker"));
    int Victim = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(Attacker))
    {
        i_KillCount[Attacker]++;

        
        if(i_KillCount[Attacker] == ksreward_kills.IntValue)
        {
            GivePlayerItem(Attacker, g_szAward)
            i_KillCount[Attacker] = 0;
        }
    }

    if(IsValidClient(Victim))
    {
        i_KillCount[Victim] = 0;
    }
    return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
} 