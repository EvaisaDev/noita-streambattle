dofile_once("mods/evaisa.streambattle/files/scripts/lib/utils.lua")
dofile_once("data/scripts/streaming_integration/event_list.lua")
dofile_once("data/scripts/streaming_integration/event_utilities.lua")
dofile_once("mods/evaisa.streambattle/files/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk.lua")

gui = GuiCreate()

GuiStartFrame(gui)

local year, month, day, hour, minute, second = GameGetDateAndTimeUTC()

local random_seed = year + month + day + hour + minute + second / 3

SetRandomSeed(random_seed, random_seed)

local game_states = {
	idle = "Idle",
	waiting = "Waiting",
	starting = "Starting",
	running = "Running",
	ending = "Ending",
}

local window_states = {
	closed = 0,
	new_game = 1,
	match = 2,
	leaderboard = 3,
}

function perk_spawn2( x, y, perk_id )
	local perk_data = get_perk_with_id( perk_list, perk_id )
	if ( perk_data == nil ) then
		print_error( "spawn_perk( perk_id ) called with'" .. perk_id .. "' - no perk with such id exists." )
		return
	end

	print( "spawn_perk " .. tostring( perk_id ) .. " " .. tostring( x ) .. " " .. tostring( y ) )

	---
	local entity_id = EntityLoad( "data/entities/items/pickup/perk.xml", x, y )
	if ( entity_id == nil ) then
		return
    end
    
    EntityRemoveTag(entity_id, "perk")
    EntityAddTag(entity_id, "perk2")

    luacomp = EntityGetFirstComponent(entity_id, "LuaComponent" )

    ComponentSetValue(luacomp, "script_item_picked_up", "mods/twitch_extended/files/scripts/perks/perk_pickup.lua")

	-- init perk item
	EntityAddComponent( entity_id, "SpriteComponent", 
	{ 
		image_file = perk_data.perk_icon or "data/items_gfx/perk.xml",  
		offset_x = "8", 
		offset_y = "8", 
		update_transform = "1" ,
		update_transform_rotation = "0",
	} )

	EntityAddComponent( entity_id, "UIInfoComponent", 
	{ 
		name = perk_data.ui_name,
	} )

	EntityAddComponent( entity_id, "ItemComponent", 
	{ 
		item_name = perk_data.ui_name,
		ui_description = perk_data.ui_description,
		play_spinning_animation = "0",
		play_hover_animation = "0",
		play_pick_sound = "0",
	} )

	EntityAddComponent( entity_id, "SpriteOffsetAnimatorComponent", 
	{ 
      sprite_id="-1" ,
      x_amount="0" ,
      x_phase="0" ,
      x_phase_offset="0" ,
      x_speed="0" ,
      y_amount="2" ,
      y_speed="3",
	} )

	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{ 
		name = "perk_id",
		value_string = perk_data.id,
	} )

	return entity_id
end

local game_handler = {
	version = "1.0.0",
	stored_users = {},
	stored_chat_messages = {},
	game_state = game_states.idle,
	window_state = window_states.new_game,
	focus = 0,
	players = {},
	leaderboard = {},
	timeouts = {},
	countdown = 0,
	death_count = 0,
	arenas = {
		{
			name = "Coal Pits",
			color = 0xfffc5c47,
		}
	},
	settings = {
		map = nil,
		seed = Random(2147483646) + Random(2147483646),
		enemies = true,
		props = true,
		lanterns = true,
		items = true,
		countdown = 10,
		timeout = 20,
		arena_size = 2,
	},
	GetLivingPlayers = function(self)
		local players = {}
		for _, player in pairs(self.players) do
			if(player.alive)then
				table.insert(players, player)
			end
		end
		return players
	end,
	OnChatMessage = function(self, data)
		if(data.message == "!play" and (self.game_state == game_states.waiting or self.game_state == game_states.starting))then
			if(not self.players[data.userid])then
				local fakeid = Random(100,10000)
				self.players[data.userid] = {
					kills = 0,
					alive = true,
					name = data.name,
				}

				local spawn_points = EntityGetWithTag("arena_spawnpoint")

				local spawn_point = spawn_points[math.random(1, #spawn_points)]

				local spawn_x, spawn_y = EntityGetTransform(spawn_point)

				local mina = EntityLoad("mods/evaisa.streambattle/files/entities/mina/mina.xml", spawn_x, spawn_y) --spawn_item("mods/evaisa.streambattle/files/entities/mina/mina.xml", spawn_x, spawn_y, 0, 100, true, false)
				
				--<Entity><Base file="data/entities/items/starting_wand_rng.xml" /></Entity>
				--<Entity><Base file="data/entities/items/starting_bomb_wand_rng.xml" /></Entity>
				--<Entity><Base file="data/entities/items/pickup/potion_starting.xml" /></Entity>

				local mina_x, mina_y = EntityGetTransform(mina)

				EntityLoad("data/entities/items/starting_wand_rng.xml", mina_x, mina_y)
				EntityLoad("data/entities/items/starting_bomb_wand_rng.xml", mina_x, mina_y)
				EntityLoad("data/entities/items/pickup/potion_starting.xml", mina_x, mina_y)
				
				-- find child entity with name "nametag"
				local children = EntityGetAllChildren(mina)
				for i, child in ipairs(children) do
					local name = EntityGetName(child)
					if(name == "nametag")then
						local sprite_component = EntityGetFirstComponentIncludingDisabled(child, "SpriteComponent")
						ComponentSetValue2(sprite_component, "text", data.name)
						ComponentSetValue2(sprite_component, "offset_x", string.len(data.name)*1.9)
					end
				end

				local damage_model = EntityGetFirstComponentIncludingDisabled(mina, "DamageModelComponent")
				EntitySetComponentIsEnabled(mina, damage_model, false)

				self.players[data.userid].mina = mina
			end
		end
		if(not self.timeouts[data.userid] and self.game_state == game_states.running)then
			if(data.message == "!bomb")then

				local players = self:GetLivingPlayers()

				local player = players[math.random(1, #players)]
				local mina = player.mina

				GamePrint(data.name.." dropped a bomb on "..player.name)

				local spawn_x, spawn_y = EntityGetTransform(mina)

				spawn_item("mods/evaisa.streambattle/files/entities/projectiles/tnt.xml", spawn_x, spawn_y, 10, 30, false, false)

				-- add cooldown
				self.timeouts[data.userid] = self.settings.timeout
			end
			if(data.message == "!wand")then
				local players = self:GetLivingPlayers()

				local player = players[math.random(1, #players)]
				local mina = player.mina

				GamePrint(data.name.." gave a wand to "..player.name)

				local x, y = EntityGetTransform(mina)

				local spawn_x, spawn_y = get_spawn_pos(x, y, 5, 50)

				local rnd = Random(0,100)
			
				if( rnd <= 25 ) then
					EntityLoad( "data/entities/items/wand_level_04.xml", spawn_x + Random(-10,10), spawn_y - 4 + Random(-10,10) )
				elseif( rnd <= 50 ) then
					EntityLoad( "data/entities/items/wand_unshuffle_04.xml", spawn_x + Random(-10,10), spawn_y - 4 + Random(-10,10) )
				elseif( rnd <= 75 ) then
					EntityLoad( "data/entities/items/wand_level_05.xml", spawn_x + Random(-10,10), spawn_y - 4 + Random(-10,10) )
				elseif( rnd <= 90 ) then
					EntityLoad( "data/entities/items/wand_unshuffle_05.xml", spawn_x + Random(-10,10), spawn_y - 4 + Random(-10,10) )
				elseif( rnd <= 97 ) then
					EntityLoad( "data/entities/items/wand_level_06.xml", spawn_x + Random(-10,10), spawn_y - 4 + Random(-10,10) )
				elseif( rnd <= 100 ) then
					EntityLoad( "data/entities/items/wand_unshuffle_06.xml", spawn_x + Random(-10,10), spawn_y - 4 + Random(-10,10) )
				end

				self.timeouts[data.userid] = self.settings.timeout
			end
			if(data.message == "!perk")then
				local players = self:GetLivingPlayers()

				local player = players[math.random(1, #players)]
				local mina = player.mina

				GamePrint(data.name.." gave a perk to "..player.name)

				local x, y = EntityGetTransform(mina)

				local perk = perk_list[Random(1, #perk_list)]

				local spawn_x, spawn_y = get_spawn_pos(x, y, 5, 50)

				if spawn_x ~= nil and spawn_y ~= nil then
					local perk_entity = perk_spawn2(spawn_x, spawn_y - 8, perk.id)
				end

				self.timeouts[data.userid] = self.settings.timeout
			end
		end
	end,
	RenderMarkers = function(self)
		dofile("mods/evaisa.streambattle/files/scripts/gui_utils.lua")
		local screen_width, screen_height = GuiGetScreenDimensions(gui)
		local screen_center_x, screen_center_y = screen_width/2, screen_height/2
		local camera_x, camera_y = GameGetCameraPos()
		local bounds_x, bounds_y, bounds_w, bounds_h = GameGetCameraBounds()
		-- loop through each player
		for userid, player in pairs(self.players)do
			if(player.alive and EntityGetIsAlive(player.mina))then
				local x, y = EntityGetTransform(player.mina)
				-- direction from camera to player
				local dx, dy = x - camera_x, y - camera_y


				-- check if player is outside camera bounds
				if(x < bounds_x or y < bounds_y or x > bounds_x + bounds_w or y > bounds_y + bounds_h)then
		
					-- normalize that shit
					local length = math.sqrt(dx*dx + dy*dy)
					dx, dy = dx/length, dy/length

					-- draw a marker on the edge of the screen in the direction of the player
					-- march from screen center in direction until we are off screen
					local marker_x, marker_y = screen_center_x, screen_center_y
					while(marker_x > 0 and marker_x < screen_width and marker_y > 0 and marker_y < screen_height)do
						marker_x = marker_x + dx
						marker_y = marker_y + dy
					end

					
					-- subtract 10 so that we are away from the edge a bit
					marker_x = marker_x - 10*dx
					marker_y = marker_y - 10*dy

					
					local markers = {
						up = "mods/evaisa.streambattle/files/gfx/ui/marker/top.png",
						down = "mods/evaisa.streambattle/files/gfx/ui/marker/bottom.png",
						left = "mods/evaisa.streambattle/files/gfx/ui/marker/left.png",
						right = "mods/evaisa.streambattle/files/gfx/ui/marker/right.png",
						topleft = "mods/evaisa.streambattle/files/gfx/ui/marker/topleft.png",
						topright = "mods/evaisa.streambattle/files/gfx/ui/marker/topright.png",
						bottomleft = "mods/evaisa.streambattle/files/gfx/ui/marker/bottomleft.png",
						bottomright = "mods/evaisa.streambattle/files/gfx/ui/marker/bottomright.png",
					}

					-- figure out which marker to draw based on the direction

					local marker_image = markers.up
					if(marker_x < screen_center_x - (screen_center_x / 2) and marker_y < screen_center_y - (screen_center_y / 2))then
						marker_image = markers.topleft
					elseif(marker_x > screen_center_x + (screen_center_x / 2) and marker_y < screen_center_y - (screen_center_y / 2))then
						marker_image = markers.topright
					elseif(marker_x < screen_center_x - (screen_center_x / 2) and marker_y > screen_center_y + (screen_center_y / 2))then
						marker_image = markers.bottomleft
					elseif(marker_x > screen_center_x + (screen_center_x / 2) and marker_y > screen_center_y + (screen_center_y / 2))then
						marker_image = markers.bottomright
					elseif(marker_x < screen_center_x - (screen_center_x / 2))then
						marker_image = markers.left
					elseif(marker_x > screen_center_x + (screen_center_x / 2))then
						marker_image = markers.right
					elseif(marker_y < screen_center_y - (screen_center_y / 2))then
						marker_image = markers.up
					elseif(marker_y > screen_center_y + (screen_center_y / 2))then
						marker_image = markers.down
					end

						

					--marker_x, marker_y = marker_x / 2, marker_y / 2
					
					marker_x = marker_x - 2.5
					marker_y = marker_y - 2.5

					GuiImage(gui, NewID("Markers"), marker_x, marker_y, marker_image, 1, 1)
					--GuiText(gui, marker_x / 2, marker_y / 2, "o")
				end
			end
		end
	end,
	CheckPlayerStatus = function(self)
		if(self.game_state == game_states.running)then
			for userid, player in pairs(self.players)do
				if(player.alive)then
					if(not EntityGetIsAlive(player.mina))then
						local focus_entity = tonumber(GlobalsGetValue("focus_entity", "0"))
						if(focus_entity == player.mina)then
							GameSetCameraFree(true)
							GlobalsSetValue("focus_entity", "0")
						end

						table.insert(self.leaderboard, 1, player)
						player.alive = false
						self.death_count = self.death_count + 1
						GamePrint(player.name.." has died.")
					end
				end
			end
			
			if(self.death_count >= (getTableSize(self.players) - 1))then
				for userid, player in pairs(self.players)do
					if(player.alive)then
						table.insert(self.leaderboard, 1, player)
					end
				end
				self.game_state = game_states.ending
				self.window_state = window_states.leaderboard
			end
			
		end
	end,
	RenderHud = function(self)

		local screen_width, screen_height = GuiGetScreenDimensions(gui)

		

		dofile("mods/evaisa.streambattle/files/scripts/gui_utils.lua")
		local screen_width, screen_height = GuiGetScreenDimensions(gui)
		local windows = {
			{
				name = "New Arena",
				func = function()
					local window_width = 200
					local window_height = 180
				
					local window_text = "New Arena"
				
					DrawWindow(gui, -4000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
						GuiLayoutBeginVertical(gui, 0, 0, true, 0, 0)
		
						self.settings.map = self.settings.map or 1

						if(GuiButton(gui, NewID("NewArena"), 2, 1, "Map: "..self.arenas[self.settings.map].name))then
							self.settings.map = self.settings.map + 1
							if(self.settings.map > #self.arenas)then
								self.settings.map = 1
							end
						end


						GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
						GuiText(gui, 2, 4, "World seed: ")
						local seed_value = tonumber(GuiTextInput(gui, NewID("NewArena"), 2, 4, tostring(self.settings.seed), 120, 10, "1234567890") or 1)
						if(self.settings.seed ~= seed_value)then
							self.settings.seed = seed_value
							
							if(self.settings.seed > 400000000)then
								self.settings.seed = 400000000
							elseif(self.settings.seed < 1)then
								self.settings.seed = 1
							end
							
						end
						if(GuiImageButton(gui, NewID("NewArena"), -2, 4.15, "", "mods/evaisa.streambattle/files/gfx/ui/random.png"))then
							self.settings.seed = Random(2147483646) + Random(2147483646)
							GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
						end
						GuiLayoutEnd(gui)


						GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
						GuiText(gui, 2, 6, "Arena size: ")
						local slider_value_size = GuiSlider(gui, NewID("NewArena"), 0, 7, "", self.settings.arena_size, 1, 6, 2, 1, " $0", 90)
						if(slider_value_size ~= self.settings.arena_size)then
							self.settings.arena_size = slider_value_size
						end
						GuiLayoutEnd(gui)



						if(GuiButton(gui, NewID("NewArena"), 2, 8, self.settings.enemies and "Enemies: [Enabled]" or "Enemies: [Disabled]"))then
							self.settings.enemies = not self.settings.enemies
						end

						if(GuiButton(gui, NewID("NewArena"), 2, 4, self.settings.props and "Props: [Enabled]" or "Props: [Disabled]"))then
							self.settings.props = not self.settings.props
						end

						if(GuiButton(gui, NewID("NewArena"), 2, 4, self.settings.lanterns and "Lamps: [Enabled]" or "Lamps: [Disabled]"))then
							self.settings.lanterns = not self.settings.lanterns
						end

						if(GuiButton(gui, NewID("NewArena"), 2, 4, self.settings.items and "Items: [Enabled]" or "Items: [Disabled]"))then
							self.settings.items = not self.settings.items
						end

						GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
						GuiText(gui, 2, 3, "Command timeout: ")
						local slider_value = GuiSlider(gui, NewID("NewArena"), 0, 4, "", self.settings.timeout, 0, 60, 20, 1, " $0s", 90)
						if(slider_value ~= self.settings.timeout)then
							self.settings.timeout = slider_value
						end
						GuiLayoutEnd(gui)

		
						GuiText(gui, 2, 4, "--------------------")

						if(GuiButton(gui, NewID("NewArena"), 2, 2, "Create arena"))then
							self.settings.map = self.settings.map or 1
							local arena = self.arenas[self.settings.map]

							GlobalsSetValue("streambattle_biome", tostring(arena.color))
							GlobalsSetValue("streambattle_enemies", tostring(self.settings.enemies))
							GlobalsSetValue("streambattle_props", tostring(self.settings.props))
							GlobalsSetValue("streambattle_lanterns", tostring(self.settings.lanterns))
							GlobalsSetValue("streambattle_items", tostring(self.settings.items))
							GlobalsSetValue("streambattle_size", tostring(self.settings.arena_size))

							local world_entity_id = GameGetWorldStateEntity()
							if( world_entity_id ~= nil ) then
								local comp_worldstate = EntityGetFirstComponent( world_entity_id, "WorldStateComponent" )
								if( comp_worldstate ~= nil ) then
									ComponentSetValue( comp_worldstate, "global_genome_relations_modifier", "10000" )
								end
							end

							SetWorldSeed(self.settings.seed)
							BiomeMapLoad_KeepPlayer("mods/evaisa.streambattle/files/scripts/generate_new_map.lua")

							GameSetCameraPos(-100, -100)
							GameSetCameraPos(100, 100)
							GameSetCameraPos(-100, 100)
							GameSetCameraPos(100, -100)

							GameSetCameraPos((self.settings.arena_size * 512) / 2, (self.settings.arena_size * 512) / 2)

							--LoadPixelScene("mods/evaisa.streambattle/files/arena.png", "mods/evaisa.streambattle/files/arena_visuals.png", 0, 0, "mods/evaisa.streambattle/files/arena_background.png")
							
							self.window_state = window_states.match
							self.game_state = game_states.waiting
						end

						for i = 1, 40 do
							GuiText(gui, 2, 0, " ")
						end
						GuiLayoutEnd(gui)
					end)
				end
			},
			{
				name = "Arena Lobby",
				func = function()
					local window_width = 140
					local window_height = 180
				
					local window_text = "Arena Lobby"
				
					DrawWindow(gui, -4000, (screen_width - (window_width / 2)) - 20, screen_height / 2, window_width, window_height, window_text, true, function()
						GuiLayoutBeginVertical(gui, 0, 0, true, 0, 0)
		
		
						if(GuiButton(gui, NewID("NewArena"), 2, 2, "< Back to menu"))then
							self.game_state = game_states.idle
							self.window_state = window_states.new_game
							self.players = {}
							self.leaderboard = {}
							self.death_count = 0
							self.timeouts = {}
							BiomeMapLoad_KeepPlayer("mods/evaisa.streambattle/files/scripts/initial_map.lua")

							GameSetCameraPos(-100, -100)
							GameSetCameraPos(100, 100)
							GameSetCameraPos(-100, 100)
							GameSetCameraPos(100, -100)		
							
							local spawn_points = EntityGetWithTag("arena_spawnpoint") or {}

							for k, v in ipairs(spawn_points)do
								EntityKill(v)
							end

							GameSetCameraFree(true)
						end
						
						

						if(self.game_state == game_states.waiting or self.game_state == game_states.starting)then
							if(getTableSize(self.players) > 0)then
								if(GuiButton(gui, NewID("NewArena"), 2, 2, "Start match"))then
								
									self.countdown = self.settings.countdown
									self.timeouts = {}

									self.game_state = game_states.starting
								end
							end
							GuiText(gui, 2, -4, " ")
							GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
							GuiText(gui, 2, 4, "Type !")
							GuiText(gui, 1, 4, "play to join the battle!")
							GuiLayoutEnd(gui)	
						end

						if(self.game_state == game_states.starting)then
							
							if(GameGetFrameNum() % 60 == 0)then
								self.countdown = self.countdown - 1
							end
							GuiText(gui, 2, 4, "Game starting in "..tostring(self.countdown))

							if(self.countdown <= 0)then
								local world_entity_id = GameGetWorldStateEntity()
								if( world_entity_id ~= nil ) then
									local comp_worldstate = EntityGetFirstComponent( world_entity_id, "WorldStateComponent" )
									if( comp_worldstate ~= nil ) then
										ComponentSetValue( comp_worldstate, "global_genome_relations_modifier", "-10000" )
									end
								end

								for userid, player in pairs(self.players)do
									if(player.alive and EntityGetIsAlive(player.mina))then
										local damage_model = EntityGetFirstComponentIncludingDisabled(player.mina, "DamageModelComponent")
										EntitySetComponentIsEnabled(player.mina, damage_model, true)
									end
								end

								self.game_state = game_states.running
							end
						end

						if(self.game_state == game_states.running)then
							GuiText(gui, 2, -4, " ")
							GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
							GuiText(gui, 2, 4, "!")
							GuiText(gui, 1, 4, "bomb) Spawn bomb")
							GuiLayoutEnd(gui)	
							GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
							GuiText(gui, 2, 4, "!")
							GuiText(gui, 1, 4, "perk) Spawn perk")
							GuiLayoutEnd(gui)	
							GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
							GuiText(gui, 2, 4, "!")
							GuiText(gui, 1, 4, "wand) Spawn wand")
							GuiLayoutEnd(gui)	
						end

						if(self.game_state == game_states.waiting or self.game_state == game_states.starting or self.game_state == game_states.running)then
							GuiText(gui, 2, 6, "------- Fighters -------")
							for userid, player in pairs(self.players)do
								GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
								GuiText(gui, 2, 4, player.name)
								if(not player.alive)then
									GuiText(gui, 0, 4, " (Dead)")
								else
									if(GuiButton(gui, NewID("NewArena"), 0, 4, " [Focus]"))then
										local x, y = EntityGetTransform(player.mina)
										GameSetCameraFree(true)
										GameSetCameraPos(x, y)
									end

									if(GuiButton(gui, NewID("NewArena"), 0, 4, " [Follow]"))then
										GlobalsSetValue("focus_entity", tostring(player.mina))
										GameSetCameraFree(false)
									end
									
								end
								GuiLayoutEnd(gui)
							end
						end

						for i = 1, 40 do
							GuiText(gui, 2, 0, " ")
						end
						GuiLayoutEnd(gui)
					end)
				end
			},
			{
				name = "Final Scoreboard",
				func = function()
					local window_width = 200
					local window_height = 180
				
					local window_text = "Final Scoreboard"
				
					DrawWindow(gui, -4000, screen_width / 2, screen_height / 2, window_width, window_height, window_text, true, function()
						GuiLayoutBeginVertical(gui, 0, 0, true, 0, 0)
						if(GuiButton(gui, NewID("NewArena"), 2, 2, "< Back to menu"))then
							self.game_state = game_states.idle
							self.window_state = window_states.new_game
							self.players = {}
							self.death_count = 0
							self.leaderboard = {}
							BiomeMapLoad_KeepPlayer("mods/evaisa.streambattle/files/scripts/initial_map.lua")

							GameSetCameraPos(-100, -100)
							GameSetCameraPos(100, 100)
							GameSetCameraPos(-100, 100)
							GameSetCameraPos(100, -100)	

							local spawn_points = EntityGetWithTag("arena_spawnpoint") or {}

							for k, v in ipairs(spawn_points)do
								EntityKill(v)
							end
							
							GameSetCameraFree(true)
						end

						GuiText(gui, 2, 6, "----------- Final Scores -----------")

						for i, player in pairs(self.leaderboard)do
							GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
							GuiText(gui, 2, 4, "#"..tostring(i)..") "..player.name)
							if(not player.alive)then
								GuiText(gui, 0, 4, " (Dead)")
							end
							GuiLayoutEnd(gui)
						end

						for i = 1, 40 do
							GuiText(gui, 2, 0, " ")
						end
						GuiLayoutEnd(gui)
					end)
				end
			},
		}

		if(self.window_state ~= window_states.closed)then
			windows[self.window_state].func()
		end
	end,
	HandleCooldowns = function(self)
		-- reverse loop and remove people that have no cooldown
		for k, v in pairs(self.timeouts) do
			if(GameGetFrameNum() % 60 == 0)then
				self.timeouts[k] = self.timeouts[k] - 1
			end
			if(self.timeouts[k] <= 0)then
				self.timeouts[k] = nil
			end
		end
	end,
	PlayerDigging = function(self)
		if(self.game_state == game_states.running)then
			for userid, player in pairs(self.players)do
				if(player.alive)then
					if(EntityGetIsAlive(player.mina))then
						local x, y = EntityGetTransform(player.mina)
						local animal_ai_component = EntityGetFirstComponentIncludingDisabled(player.mina, "AnimalAIComponent")
						local prey = ComponentGetValue2(animal_ai_component, "mGreatestPrey")


						if(prey == nil or prey == 0)then

							-- find closest mina
							local closest_mina = nil
							local closest_distance = 99999999
							for k, v in ipairs(EntityGetWithTag("mina"))do
								if(v ~= player.mina)then
									local mina_x, mina_y = EntityGetTransform(v)
									local distance = math.sqrt((mina_x - x)^2 + (mina_y - y)^2)
									if(distance < closest_distance)then
										closest_mina = v
										closest_distance = distance
									end
								end
							end

							if(closest_mina ~= nil)then

								-- get direction to closest mina
								local mina_x, mina_y = EntityGetTransform(closest_mina)
								local direction = math.atan2(mina_y - y, mina_x - x)
								local direction_x = math.cos(direction)
								local direction_y = math.sin(direction)

								-- normaize
								local distance = math.sqrt(direction_x^2 + direction_y^2)
								local dir_x = direction_x / distance
								local dir_y = direction_y / distance

								

								shoot_projectile( player.mina, "mods/evaisa.streambattle/files/entities/projectiles/dig.xml", x, y, dir_x * 600, dir_y * 600 )
							end
						end
					end
				end
			end
		end
	end,
	CameraUpdate = function(self)
		local players = get_players() or {}
		if(players[1])then
			local player = players[1]
			local controls_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")

			local mButtonDownChangeItemR = ComponentGetValue2(controls_component, "mButtonDownChangeItemR")
			local mButtonDownChangeItemL = ComponentGetValue2(controls_component, "mButtonDownChangeItemL")

			local focus = self.focus
			if(mButtonDownChangeItemR)then
				if(focus < #self.players)then
					GlobalsSetValue("focus_entity", tostring(self.players[focus + 1].mina))
					self.focus = focus + 1
					GameSetCameraFree(false)
				else
					GlobalsSetValue("focus_entity", tostring(self.players[1].mina))
					self.focus = 1
					GameSetCameraFree(false)
				end
			end
			if(mButtonDownChangeItemL)then
				if(focus > 2)then
					GlobalsSetValue("focus_entity", tostring(self.players[focus - 1].mina))
					self.focus = focus - 1
					GameSetCameraFree(false)
				else
					GlobalsSetValue("focus_entity", tostring(self.players[#self.players].mina))
					self.focus = #self.players
					GameSetCameraFree(false)
				end
			end
		end
	end,
	Update = function(self)
		GuiStartFrame(gui)

		self:RenderMarkers()
		self:RenderHud()
		self:CheckPlayerStatus()
		self:HandleCooldowns()
		self:PlayerDigging()
		self:CameraUpdate()
		

		if(GlobalsGetValue("streambattle_chat_message_id", "") ~= "")then

			local full_message_data = {

			}

			local index = 1
			for msg_id in string.gmatch(GlobalsGetValue("streambattle_chat_message_id", ""), '([^(||)]+)') do

				full_message_data[msg_id] = {}
				full_message_data[msg_id].id = msg_id
				--print(msg_id)
				index = index + 1
			end
			index = 1
			for msg_color2 in string.gmatch(GlobalsGetValue("streambattle_chat_message_color", ""), '([^(||)]+)') do
				local msg_id, msg_color = msg_color2:match("([^,]+)::([^,]+)")
				if(full_message_data[msg_id])then
					full_message_data[msg_id].color = msg_color
				end
				index = index + 1
			end
			index = 1
			for msg_name2 in string.gmatch(GlobalsGetValue("streambattle_chat_message_name", ""), '([^(||)]+)') do
				local msg_id, msg_name = msg_name2:match("([^,]+)::([^,]+)")
				if(full_message_data[msg_id])then
					full_message_data[msg_id].name = msg_name
				end
				index = index + 1
			end
			index = 1
			for msg_userid in string.gmatch(GlobalsGetValue("streambattle_chat_message_userid", ""), '([^(||)]+)') do
				local msg_id, msg_userid = msg_userid:match("([^,]+)::([^,]+)")
				if(full_message_data[msg_id])then
					full_message_data[msg_id].userid = msg_userid
				end
				index = index + 1
			end


			index = 1
			for msg_message2 in string.gmatch(GlobalsGetValue("streambattle_chat_message_content", ""), '([^(||)]+)') do
				local msg_id, msg_message = msg_message2:match("([^,]+)::([^,]+)")
				if(full_message_data[msg_id])then
					full_message_data[msg_id].message = msg_message
				end
				index = index + 1
			end
			index = 1
			for msg_broadcaster2 in string.gmatch(GlobalsGetValue("streambattle_chat_message_broadcaster", ""), '([^(||)]+)') do
				local msg_id, msg_broadcaster = msg_broadcaster2:match("([^,]+)::([^,]+)")
				if(full_message_data[msg_id])then
					full_message_data[msg_id].broadcaster = msg_broadcaster
				end
				index = index + 1
			end
			index = 1
			for msg_subscriber2 in string.gmatch(GlobalsGetValue("streambattle_chat_message_subscriber", ""), '([^(||)]+)') do
				local msg_id, msg_subscriber = msg_subscriber2:match("([^,]+)::([^,]+)")
				if(full_message_data[msg_id])then
					full_message_data[msg_id].subscriber = msg_subscriber
				end
				index = index + 1
			end
			index = 1
			for msg_moderator2 in string.gmatch(GlobalsGetValue("streambattle_chat_message_moderator", ""), '([^(||)]+)') do
				local msg_id, msg_moderator = msg_moderator2:match("([^,]+)::([^,]+)")
				if(full_message_data[msg_id])then
					full_message_data[msg_id].moderator = msg_moderator
				end
				index = index + 1
			end
			index = 1
			for msg_frame2 in string.gmatch(GlobalsGetValue("streambattle_chat_message_frame", ""), '([^(||)]+)') do
				local msg_id, msg_frame = msg_frame2:match("([^,]+)::([^,]+)")
				if(full_message_data[msg_id])then
					full_message_data[msg_id].frame = msg_frame
				end
				index = index + 1	
			end

			for k, msg in pairs(full_message_data)do
				if(#self.stored_chat_messages >= 7)then
					table.remove(self.stored_chat_messages, 1)
				end
				
				local message_table = {
					id = msg.id,
					color = msg.color,
					name = msg.name,
					userid = msg.userid,
					message = msg.message,
					broadcaster = (msg.broadcaster == "true" or false),
					subscriber = (msg.subscriber == "true" or false),
					moderator = (msg.moderator == "true" or false),
					frame = tonumber(msg.frames)
				}
			
				--print(table.dump(message_table))
			
				table.insert(self.stored_chat_messages, message_table)

				self:OnChatMessage(message_table)
			
				local has_user = false
				for k, v in pairs(self.stored_users)do
					if(v.name == GlobalsGetValue("streambattle_chat_message_name", ""))then
						has_user = true
					end
				end
			
				if(has_user == false)then
					local current_user = {
						color = msg.color,
						name = msg.name,
						userid = msg.userid,
						broadcaster = (msg.broadcaster == "true" or false),
						subscriber = (msg.subscriber == "true" or false),
						moderator = (msg.moderator == "true" or false),
						frame = tonumber(msg.frames)
					}
			
					table.insert(self.stored_users, current_user)
				end
			
			end
			GlobalsSetValue("streambattle_chat_message_id", "")
			GlobalsSetValue("streambattle_chat_message_color", "")
			GlobalsSetValue("streambattle_chat_message_name", "")
			GlobalsSetValue("streambattle_chat_message_userid", "")
			GlobalsSetValue("streambattle_chat_message_content", "")
			GlobalsSetValue("streambattle_chat_message_broadcaster", "")
			GlobalsSetValue("streambattle_chat_message_subscriber", "")
			GlobalsSetValue("streambattle_chat_message_moderator", "")
			GlobalsSetValue("streambattle_chat_message_frames", "")
		end
	end
}

return game_handler