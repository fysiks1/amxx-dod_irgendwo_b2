#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

new g_entSpawns[2][68] // info_player_allies x 68, info_player_axis x 68
new g_szSpawnMasters[2][68][20]
new g_szSpawnOrigins[2][68][20]
new g_iSpawns[2]
new g_entObject[10] // dod_object x 10
new g_entTriggerHurtAllies[4] // trigger_hurt + spawnflags 64 x 4
new g_entTriggerHurtAxis[4] // trigger_hurt + spawnflags 128 x 4
new g_entControlPoints[10] // dod_control_point x 10
new g_entScore[2] // dod_score_ent x 2
new g_entPointRelay // dod_point_relay x 1

new g_iHurtCountAllies = 0
new g_iHurtCountAxis = 0
new g_iObjectCount = 0
new g_iControlPointsCount = 0

// Settings per state
new g_iHurtSpawnFlags[2] = {64, 128}
new g_iObjectOwner[2][] = {"2","1"}
new g_iTeam[2] = {1,2}
new g_szTeam[2][] = {"1","2"}
new g_szCanTouch[2][] = {"0","1"}
new g_szWinMessage[2][] = {"The Allies have captured the town", "The Axis have captured the town"}
new g_szPointTarget[sizeof(g_entControlPoints)][][] = {
	{"police_captured", ""},
	{"townhall_captured", ""},
	{"shop_captured", ""},
	{"arches_captured", ""},
	{"streets_captured", ""},
	{"factory_captured", ""},
	{"allies_fastcap", ""},
	{"allies_capture", ""},
	{"", ""},
	{"", ""}
}

new g_iState = 0

public plugin_init()
{
	register_plugin("Switch Teams dod_irgendwo_b2", "1.0", "Fysiks")
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
}

public pfn_keyvalue(entid)
{
	static szClassName[32], szKeyName[32], szValue[32], iValue = 0, team = 0
	szClassName[0] = 0, szKeyName[0] = 0, szValue[0] = 0
	copy_keyvalue(szClassName, charsmax(szClassName), szKeyName, charsmax(szKeyName), szValue, charsmax(szValue))

	if( equal(szClassName, "dod_score_ent") )
	{
		if( equal(szKeyName, "team") )
		{
			switch( szValue[0] )
			{
				case '1': g_entScore[0] = entid
				case '2': g_entScore[1] = entid
			}
		}
	}
	else if( equal(szClassName, "info_player_a", 13) )
	{
		team = !!(szClassName[13] == 'x')
		
		if( equal(szKeyName, "origin") )
		{
			g_entSpawns[team][g_iSpawns[team]] = entid
			copy(g_szSpawnOrigins[team][g_iSpawns[team]], charsmax(g_szSpawnOrigins[][]), szValue)
		}
		else if( equal(szKeyName, "master") )
		{
			copy(g_szSpawnMasters[team][g_iSpawns[team]], charsmax(g_szSpawnMasters[][]), szValue)
			g_iSpawns[team]++
		}
	}
	else if( equal(szClassName, "trigger_hurt") && equal(szKeyName, "spawnflags") )
	{
		iValue = str_to_num(szValue)
		switch(iValue)
		{
			case 64:
			{
				g_entTriggerHurtAllies[g_iHurtCountAllies] = entid
				g_iHurtCountAllies++
			}
			case 128:
			{
				g_entTriggerHurtAxis[g_iHurtCountAxis] = entid
				g_iHurtCountAxis++
			}
		}
	}
	else if( equal(szValue, "dod_object") && equal(szKeyName, "classname") )
	{
		g_entObject[g_iObjectCount] = entid
		g_iObjectCount++
	}
	else if( equal(szValue, "dod_point_relay") && equal(szKeyName, "classname") )
	{
		g_entPointRelay = entid
	}
	else if( equal(szClassName, "dod_control_point") && equal(szKeyName, "point_name") )
	{
		g_entControlPoints[g_iControlPointsCount++] = entid
		// server_print("<%s> <%s> <%s> %d", szClassName, szKeyName, szValue, entid)
	}
	// server_print("%d %d %d %d %d %d %d %d", g_iAlliesSpawnCount, g_iAxisSpawnCount, g_iObjectCount, g_iHurtCountAllies, g_iHurtCountAxis, g_entScore[0], g_entScore[1], g_entPointRelay)
}

public SwapTeams()
{
	new szArg[3], iArg
	read_argv(1, szArg, charsmax(szArg))
	iArg = str_to_num(szArg)
	set_map(iArg)
	client_print(0, print_chat, "Teams should be set")
}
public cmdSetHurt()
{
	new szArg[3], iArg
	read_argv(1, szArg, charsmax(szArg))
	iArg = str_to_num(szArg)
	set_hurt(!!iArg)
	client_print(0, print_chat, "trigger_hurt's should be set to %d", iArg)
}
public event_new_round()
{
	set_map(g_iState)
	g_iState = !g_iState
}

public set_map(iState)
{
	new i
	iState = !!iState
	
	// dod_object
	for(i = 0; i < g_iObjectCount; i++)
	{
		fm_set_kvd(g_entObject[i], "object_owner", g_iObjectOwner[iState], "dod_object")
	}
	
	set_hurt(iState)
	set_task(1.0, "set_hurt", iState)
	
	// dod_score_ent
	set_pev(g_entScore[0], pev_team, g_iTeam[iState])
	set_pev(g_entScore[0], pev_message, g_szWinMessage[iState])
	set_pev(g_entScore[1], pev_team, g_iTeam[!iState])
	
	// dod_point_relay
	fm_set_kvd(g_entPointRelay, "dod_relay_team", g_szTeam[iState], "dod_point_relay")
	
	// dod_control_point
	for(i = 0; i < g_iControlPointsCount; i++)
	{
		if( i < 8 )
		{
			// set targets
			fm_set_kvd(g_entControlPoints[i], "point_allies_target", g_szPointTarget[i][iState], "dod_control_point")
			fm_set_kvd(g_entControlPoints[i], "point_axis_target", g_szPointTarget[i][!iState], "dod_control_point")
		}

		switch(i+1)
		{
			case 7:
			{
				// set point_can_[allies|axis]_touch, this doesn't seem to work correctly . . . not sure what is wrong
				fm_set_kvd(g_entControlPoints[i], "point_can_allies_touch", g_szCanTouch[iState], "dod_control_point")
				fm_set_kvd(g_entControlPoints[i], "point_can_axis_touch", g_szCanTouch[!iState], "dod_control_point")
				
			}
			case 9:
			{
				// original default owner is 1
				fm_set_kvd(g_entControlPoints[i], "point_default_owner", g_szTeam[iState], "dod_control_point")
			}
			default:
			{
				// original default owner is 2
				fm_set_kvd(g_entControlPoints[i], "point_default_owner", g_szTeam[!iState], "dod_control_point")
			}
		}
	}
	
	// info_player_[axis|allies]
	// swap spawns
	// need to swap spawn origins as well as the master (hopefully it works because chaning the classname does not work!)
	for(i = 0; i < g_iSpawns[0]; i++)
	{
		fm_set_kvd(g_entSpawns[0][i], "origin", g_szSpawnOrigins[iState][i], "info_player_allies")
		fm_set_kvd(g_entSpawns[0][i], "master", g_szSpawnMasters[iState][i], "info_player_allies")
		
		fm_set_kvd(g_entSpawns[1][i], "origin", g_szSpawnOrigins[!iState][i], "info_player_axis")
		fm_set_kvd(g_entSpawns[1][i], "master", g_szSpawnMasters[!iState][i], "info_player_axis")
	}
		
}

public set_hurt(iState)
{
	// trigger_hurt (might need to set a task for these ents.
	new i
	for(i = 0; i < g_iHurtCountAllies; i++)
	{
		set_pev(g_entTriggerHurtAllies[i], pev_spawnflags, g_iHurtSpawnFlags[iState])
	}
	for(i = 0; i < g_iHurtCountAxis; i++)
	{
		set_pev(g_entTriggerHurtAxis[i], pev_spawnflags, g_iHurtSpawnFlags[!iState])
	}
}

public cmdSpawnInfo()
{
	new i
	for(i = 0; i < g_iSpawns[0]; i++)
	{
		server_print("Allies %02d %s %s %d", i, g_szSpawnOrigins[0][i], g_szSpawnMasters[0][i], g_entSpawns[0][i])
	}
	for(i = 0; i < g_iSpawns[1]; i++)
	{
		server_print("Axis   %02d %s %s %d", i, g_szSpawnOrigins[1][i], g_szSpawnMasters[1][i], g_entSpawns[1][i])
	}
}

public cmdHurtInfo()
{
	new i
	for(i = 0; i < g_iHurtCountAllies; i++)
	{
		server_print("%d", pev(g_entTriggerHurtAllies[i], pev_spawnflags))
		client_print(0, print_console, "%d", pev(g_entTriggerHurtAllies[i], pev_spawnflags))
	}
	for(i = 0; i < g_iHurtCountAxis; i++)
	{
		server_print("%d", pev(g_entTriggerHurtAxis[i], pev_spawnflags))
		client_print(0, print_console, "%d", pev(g_entTriggerHurtAxis[i], pev_spawnflags))
	}
}

stock fm_set_kvd(entity, const key[], const value[], const class[])
{
	set_kvd(0, KV_ClassName, class)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	return dllfunc(DLLFunc_KeyValue, entity, 0)
}



/*
dod_object (swap 1 and 2)
	-"object_owner" "2"
	+"object_owner" "1"
	
trigger_hurt (swap 64 and 128, though two trigger_hurt ents don't have any spawn flags and should be left alone)
	-"spawnflags" "128"
	+"spawnflags" "64"

dod_control_point
	"point_name" "Police Station"
		-"point_allies_target" "police_captured"
		+"point_axis_target" "police_captured"
		-"point_default_owner" "2"
		+"point_default_owner" "1"
	"point_name" "Town Hall"
		-"point_allies_target" "townhall_captured"
		-"point_default_owner" "2"
		+"point_axis_target" "townhall_captured"
		+"point_default_owner" "1"
	"point_name" "Small House"
		-"point_allies_target" "shop_captured"
		-"point_default_owner" "2"
		+"point_axis_target" "shop_captured"
		+"point_default_owner" "1"
	"point_name" "Jagdpanther"
		-"point_allies_target" "arches_captured"
		-"point_default_owner" "2"
		+"point_axis_target" "arches_captured"
		+"point_default_owner" "1"
	"point_name" "Streets"
		-"point_allies_target" "streets_captured"
		+"point_axis_target" "streets_captured"
		-"point_default_owner" "2"
		+"point_default_owner" "1"
	"point_name" "Bunker"
		-"point_default_owner" "2"
		+"point_default_owner" "1"
		-"point_allies_target" "factory_captured"
		+"point_axis_target" "factory_captured"
	"point_name" "Courtyard"
		-"point_allies_target" "allies_fastcap"
		-"point_can_axis_touch" "1"
		+"point_axis_target" "allies_fastcap"
		+"point_can_allies_touch" "1"
	"point_name" "Courtyard"
		-"point_allies_target" "allies_capture"
		-"point_default_owner" "2"
		+"point_axis_target" "allies_capture"
		+"point_default_owner" "1"
	"point_name" "a control point"
		-"point_default_owner" "1"
		+"point_default_owner" "2"
	"point_name" "a control point"
		-"point_default_owner" "2"
		+"point_default_owner" "1"

	Notes:
		point_default_owner, simply swap teams (1 or 2)
		point_allies_target needs to effectively change to point_axis_target on each instance
		
dod_score_ent
	allies:
		-"message" "The Allies have captured the town"
		-"team" "1"
		+"message" "The Axis have captured the town"
		+"team" "2"
	axis:
		-"team" "2"
		+"team" "1"
dod_point_relay
	-"dod_relay_team" "1"
	+"dod_relay_team" "2"


*/
 