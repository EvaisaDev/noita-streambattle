

local w = 70
local h = 70

local width = 1
local height = 1

BiomeMapSetSize( w, h )

local edr = 0xFF3D3D3D

-- fill the map with edr
for x = 0, w - 1 do
	for y = 0, h - 1 do
		BiomeMapSetPixel( x, y, edr )
	end
end

--[[
local biomes = {
	0xfffc5c47, -- Collapsed Mines
}

local biome = biomes[Random(1, #biomes)]

for i = -width, width do
	for j = -height, height do
		BiomeMapSetPixel( math.floor(w / 2) + i, 14 + j, biome )
	end
end 
]]

for i = -width, width do
	for j = -height, height do
		BiomeMapSetPixel( math.floor(w / 2) + i, 14 + j, 0xff48E311 )
	end
end 

