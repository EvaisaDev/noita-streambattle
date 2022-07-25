local mina = GetUpdatedEntityID()

local animal_ai = EntityGetFirstComponentIncludingDisabled(mina, "AnimalAIComponent")

local target = ComponentGetValue2(animal_ai, "mGreatestPrey") or 0

--[[
if(target ~= 0)then
	local target_x, target_y = EntityGetTransform(target)

	ComponentSetValue2(animal_ai, "mHomePosition", target_x, target_y)
	ComponentSetValue2(animal_ai, "max_distance_to_move_from_home", 100)
else
	ComponentSetValue2(animal_ai, "mHomePosition", 0, 0)
	ComponentSetValue2(animal_ai, "max_distance_to_move_from_home", 50000000)
end
]]