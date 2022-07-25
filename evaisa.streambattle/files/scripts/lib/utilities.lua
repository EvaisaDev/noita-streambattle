function create_hole_of_size(x, y, r)
	hole_maker = EntityCreateNew( "hole" )
	EntitySetTransform(hole_maker, x, y)
	EntityAddComponent(hole_maker, "CellEaterComponent", {
		radius=tostring(r)
	})
	EntityAddComponent(hole_maker, "LifetimeComponent", {
		lifetime="1"
	})
end

function get_spawn_pos(x, y, min_range, max_range)

	x = x or 0
	y = y or 0
	
	local spawn_points = {}
	
	local count = 0
	
	for i = 1, 1000 do
	
		local angle = Random()*math.pi*2;
	  
		local dx = x + (math.cos(angle)*Random(min_range, max_range));
		local dy = y + (math.sin(angle)*Random(min_range, max_range));		
		
		local rhit, rx, ry = RaytraceSurfacesAndLiquiform(dx - 2, dy - 2, dx + 2, dy + 2)
		
		
		
		if(rhit) then 
			--DEBUG_MARK( dx, dy, "bad_spawn_point",0, 0, 1 )
		else

			table.insert(spawn_points, {
				x = dx,
				y = dy,
			})
		end
	end

	if(#spawn_points == 0)then
		return x, y
	end
	local spawn_index = Random(1, #spawn_points)


	
	local spawn_x = spawn_points[spawn_index].x
	local spawn_y = spawn_points[spawn_index].y
	
	if(spawn_x == nil)then
		local angle = Random()*math.pi*2;
	  
		local dx = x + (math.cos(angle)*Random(min_range, max_range));
		local dy = y + (math.sin(angle)*Random(min_range, max_range));		
		
		--EntityLoad("mods/twitch_extended/files/entities/short_blackhole.xml", dx, dy)
		create_hole_of_size(dx, dy, 12)
		
		return dx, dy
	else

		return spawn_x, spawn_y
	end

end


function spawn_item(entity_path, x, y, min_range, max_range, black_hole, ignore_bad_spawns, hole_size)

	x = x or 0
	y = y or 0

	min_range = min_range or 0
	max_range = max_range or 0
	ignore_bad_spawns = ignore_bad_spawns or false
	hole_size = hole_size or 12
	black_hole = black_hole or false
	if(not ignore_bad_spawns)then

		spawn_x, spawn_y = get_spawn_pos(min_range, max_range, x, y)

		if black_hole then
			create_hole_of_size(spawn_x, spawn_y, hole_size)
		end
		
		return EntityLoad(entity_path, spawn_x, spawn_y)

	else
		
		local angle = Random()*math.pi*2;
		
		local dx = math.cos(angle)*Random(min_range, max_range);
		local dy = math.sin(angle)*Random(min_range, max_range);
		
		if(black_hole)then
			create_hole_of_size(x + dx, y + dy, hole_size)
			--EntityLoad("mods/twitch_extended/files/entities/short_blackhole.xml", x + dx, y + dy)
		end
		
		return EntityLoad(entity_path, x + dx, y + dy)	
	end
end