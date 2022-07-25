ModLuaFileAppend( "data/scripts/streaming_integration/event_utilities.lua", "mods/evaisa.streambattle/files/scripts/append/event_utilities.lua")

local game_handler = dofile("mods/evaisa.streambattle/files/scripts/game_handler.lua")


function split_string(inputstr, sep)
	sep = sep or "%s"
	local t= {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
	  table.insert(t, str)
	end
	return t
end


function add_new_genome(content, genome_name, default_relation_ab, default_relation_ba, self_relation, relations)
	local lines = split_string(content, "\r\n")
	local output = ""
	local genome_order = {}
	for i, line in ipairs(lines) do
		if i == 1 then
		output = output .. line .. "," .. genome_name .. "\r\n"
		else
		local herd = line:match("([%w_-]+),")
		output = output .. line .. ","..(relations[herd] or default_relation_ba).."\r\n"
		table.insert(genome_order, herd)
		end
	end

	local line = genome_name
	for i, v in ipairs(genome_order) do
		line = line .. "," .. (relations[v] or default_relation_ab)
	end
	output = output .. line .. "," .. self_relation

	return output
end

local content = ModTextFileGetContent("data/genome_relations.csv")

content = add_new_genome(content, "battle_mina", 0, 0, 0, {})

ModTextFileSetContent("data/genome_relations.csv", content)


_ModMagicNumbersFileAdd = ModMagicNumbersFileAdd

function OnPlayerSpawned(player_entity)
	GetGameEffectLoadTo( player_entity, "REMOVE_FOG_OF_WAR", true )
	GameSetCameraFree( true )
	EntitySetTransform(player_entity, 0, 0)
	--GameSetPostFxParameter("stream_zoom", 0.5, 0, 0, 0)

	--[[
	local world_entity_id = GameGetWorldStateEntity()
	if( world_entity_id ~= nil ) then
		local comp_worldstate = EntityGetFirstComponent( world_entity_id, "WorldStateComponent" )
		if( comp_worldstate ~= nil ) then
			ComponentSetValue( comp_worldstate, "global_genome_relations_modifier", "10000" )
		end
	end
	]]

	--LoadPixelScene("mods/evaisa.streambattle/files/arena.png", "mods/evaisa.streambattle/files/arena_visuals.png", -574, -750, "mods/evaisa.streambattle/files/arena_background.png")

	--[[
	for i = 0, 40 do
		EntityLoad("mods/evaisa.streambattle/files/mina/mina.xml", 0, 0)
	end
	]]

end


function OnWorldPreUpdate()
	StreamingSetVotingEnabled( false )
	game_handler:Update()
end

ModMagicNumbersFileAdd( "mods/evaisa.streambattle/files/magic_numbers.xml"  ) 
ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/evaisa.streambattle/files/scripts/append/gun_actions.lua")