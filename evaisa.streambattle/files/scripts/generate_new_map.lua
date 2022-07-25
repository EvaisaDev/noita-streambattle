

local w = 70
local h = 70

BiomeMapSetSize( w, h )

local edr = 0xFF3D3D3D

-- fill the map with edr
for x = 0, w - 1 do
	for y = 0, h - 1 do
		BiomeMapSetPixel( x, y, edr )
	end
end

print(GlobalsGetValue("streambattle_biome"))

if(GlobalsGetValue("streambattle_biome") ~= nil)then

	local biome = tonumber(GlobalsGetValue("streambattle_biome"))
	local size = tonumber(GlobalsGetValue("streambattle_size"))



	for i = 0, size - 1 do
		for j = 0, size - 1 do
			BiomeMapSetPixel( math.floor(w / 2) + i, 14 + j, biome )
		end
	end 
end


