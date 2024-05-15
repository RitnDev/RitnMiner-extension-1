-- INITIALIZE
-----------------------------------------------------------------
if not ritnlib then require("__RitnLib__/defines") end
local RitnProtoOre = require(ritnlib.defines.class.prototype.ore)
local RitnProtoItem = require(ritnlib.defines.class.prototype.item)
local RitnProtoRecipe = require(ritnlib.defines.class.prototype.recipe)
local RitnProtoTech = require(ritnlib.defines.class.prototype.tech)
-----------------------------------------------------------------
if not ritnmods then ritnmods = {} end
if not ritnmods.miner then ritnmods.miner = {
    bio = false,
    lumberjack = false,
    dectorio = false,
    alienBiomes = false,
    spaceblock = false,
    commuLogo = false,
    data = require("modules.data")
} end
-----------------------------------------------------------------
-- active options
if mods["Dectorio"] then ritnmods.miner.dectorio = true end
if mods["alien-biomes"] then ritnmods.miner.alienBiomes = true end
if mods["spaceblock"] then ritnmods.miner.spaceblock = true end
if mods["Bio_Industries"] then ritnmods.miner.bio = true end
if mods["CommuLogo"] then ritnmods.miner.commuLogo = true end

-- desactive BioIndustries si RitnLumberjack present
if ritnmods.lumberjack then 
  if ritnmods.lumberjack.enabled then ritnmods.miner.lumberjack = true end 
end
-----------------------------------------------------------------
-- remove ore
RitnProtoOre("iron-ore"):remove()
RitnProtoOre("copper-ore"):remove()
-----------------------------------------------------------------
-- change item
RitnProtoItem("stone"):changePrototype("stack_size", 200)
RitnProtoItem("iron-ore"):changePrototype("stack_size", 100)
RitnProtoItem("copper-ore"):changePrototype("stack_size", 100)
RitnProtoItem("military-science-pack"):changePrototype("icon", "__RitnMiner__/graphics/icons/military-science-pack.png")
-----------------------------------------------------------------
--Require
require("prototypes.category")
require("prototypes.item")
require("prototypes.recipes")
require("prototypes.technology")
require("prototypes.ore-extraction")
require("prototypes.map-gen-presets")
-----------------------------------------------------------------
-- change subgroup
RitnProtoItem("offshore-pump"):changeSubgroup("energy", "a-[offshore-pump]")
-----------------------------------------------------------------
-- update technology (requis : ritnlib.tech)
require("prototypes.update-technology")
-----------------------------------------------------------------
-- require - options mods :
require("mods.data-landfill")
require("mods.data-ritn-lumberjack")

--Ajoute la recherche : Miner-science-pack
if ritnmods.lumberjack then
    RitnProtoTech:addPackLab("miner-science-pack", 2)
else
    RitnProtoTech:addPackLab("miner-science-pack")
end


if ritnmods.glass ~= nil then 
  if ritnmods.glass.enabled then 
    if ritnmods.miner.bio then 
      -- ajout des recettes de gestion de la pierre broyée
      require("prototypes.recipes.stone-brick")

      -- changement dans la recette : bi-stone-brick (fabrication de brique à partir de cendre)
      local biStoneBrickRecipe = RitnProtoRecipe("bi-stone-brick")
      biStoneBrickRecipe:addNewIngredient({type="fluid", name="water", amount=10})
      biStoneBrickRecipe:changePrototype("category", "ritn-glass-chemistry")
      biStoneBrickRecipe:changePrototype("energy_required", 16)

      require("prototypes.recipes.stone")
    end
  end
end

