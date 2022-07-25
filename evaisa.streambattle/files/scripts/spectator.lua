local focus_entity = tonumber(GlobalsGetValue("focus_entity", "0"))

local player = GetUpdatedEntityID()

local controls_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")

if(focus_entity ~= 0 and EntityGetIsAlive(focus_entity))then
	local x, y = EntityGetTransform(focus_entity)

	EntitySetTransform(player, x, y)

	local up = ComponentGetValue2(controls_component, "mButtonDownUp")
	local down = ComponentGetValue2(controls_component, "mButtonDownDown")
	local left = ComponentGetValue2(controls_component, "mButtonDownLeft")
	local right = ComponentGetValue2(controls_component, "mButtonDownRight")

	if(up or down or left or right)then
		GameSetCameraFree(true)
		GlobalsSetValue("focus_entity", "0")
	end
else
	
	local x, y = GameGetCameraPos()

	EntitySetTransform(player, x, y)
end