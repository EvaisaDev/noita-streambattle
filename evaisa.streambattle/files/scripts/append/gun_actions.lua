for k, v in ipairs(actions)do
	local old_action = v.action
	v.action = function( recursion_level, iteration )
		c.friendly_fire	= true
		old_action( recursion_level, iteration )
	end
end