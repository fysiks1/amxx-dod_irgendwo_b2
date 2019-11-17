#include <amxmodx>
#include <engine>
#include <fakemeta>

#define ROUND_TIMER "900" // Comment this line to remove the round timer.

public plugin_precache()
{
	/*
		{
		"origin" "384 832 88"
		"target" "axis_win"
		"round_timer_length" "900"
		"spawnflags" "1"
		"classname" "dod_round_timer"
		}
	*/

	new ent = create_entity("dod_round_timer")
	if( pev_valid(ent) )
	{
		set_pev(ent, pev_origin, {384.0, 832.0, 88.0})
		set_pev(ent, pev_spawnflags, 1)
		set_pev(ent, pev_target, "axis_win")
		fm_set_kvd(ent, "round_timer_length", ROUND_TIMER, "dod_round_timer")
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
