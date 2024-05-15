-- suppression de "subsurface-wall" venant du mod subsurface
data.raw.cliff["subsurface-wall"] = nil

local cliff_pics = table.deepcopy(data.raw["simple-entity"]["rock-big"].pictures)
for _,p in ipairs(data.raw["simple-entity"]["rock-huge"].pictures) do table.insert(cliff_pics, p) end
local cliff_collision_box = {{-0.9, -0.9}, {0.9, 0.9}}

data:extend({

    {
        type = "simple-entity",
        name = "subsurface-wall",
        flags = {"placeable-neutral", "not-on-map", "placeable-off-grid"},
        icon = table.deepcopy(data.raw["simple-entity"]["rock-huge"].icon),
        icon_size = table.deepcopy(data.raw["simple-entity"]["rock-huge"].icon_size),
        icon_mipmaps = table.deepcopy(data.raw["simple-entity"]["rock-huge"].icon_mipmaps),
        orientations = {
        west_to_east = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        north_to_south = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        east_to_west  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        south_to_north  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        west_to_north  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        north_to_east  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        east_to_south  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        south_to_west  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        west_to_south  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        north_to_west  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        east_to_north  = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        south_to_east   = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        west_to_none   = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        none_to_east   = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        north_to_none   = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        none_to_south   = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        east_to_none   = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        none_to_west   = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        south_to_none   = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        none_to_north    = {pictures = cliff_pics, collision_bounding_box = cliff_collision_box, fill_volume = 0},
        },
        grid_size = {1, 1},
        grid_offset = {0, 0},
        --cliff_explosive = "cliff-explosives",
        selection_box = {{-0.9, -0.9}, {0.9, 0.9}},
        minable = {mining_particle = "stone-particle", mining_time = 1, results = {{name = "stone", amount_min = 10, amount_max = 30}}}
    },

})