
local miners = {
    --global refrence to all saved miners, set in on_load and on_init
    miners = {},

    --variant types of miners, TODO in future move to sub-objects
    variants = require("__aai-vehicles-miner__.miner-variants"),

    --metamethods for miners.miners
    mt = {
        --miners[number] will return miners.miners[number]
        __index = function(tab, key)
            return type(key) == "number" and tab.miners[key]
        end,
        --__newindex: miners[number] = value store in miners.miners[number]
        __newindex = function(tab, key, value)
            if type(key) == "number" then
                tab.miners[key] = value
            else
                rawset(tab, key, value)
            end
        end
    }
}
setmetatable(miners, miners.mt)

function miners:new(entity)
    if entity and entity.valid and entity.type == "car" then
      local effective_name = entity.name
      local ai_split = string.find(effective_name, "-_-", 1, true)
      if ai_split then
        effective_name = string.sub(effective_name, 1, ai_split - 1)
      end
      effective_name = util.replace(effective_name, "-0", "")

      if self.variants[effective_name] then
        local miner = {
            unit_number = entity.unit_number,
            entity = entity,
            name = effective_name,
            stopped_on_fluid = {}
        }
        -- starting energy to collect a tree
        miner.entity.burner.currently_burning = high_fuel_item
        miner.entity.burner.remaining_burning_fuel = Prototypes.item_prototype(high_fuel_item).fuel_value * 0.001
        --metatables are not saved to global. Iterate and re-assign in on_load
        setmetatable(miner, {__index = miners})
        self[entity.unit_number] = miner
        return miner
      end
    end
end

--Replace and rekey the miner entity
function miners.replace(event)
    if miners[event.old_entity_unit_number] then
      local miner = table.deepcopy(miners[event.old_entity_unit_number])
      miner.entity = event.new_entity
      miner.unit_number = event.new_entity_unit_number
      miners[event.new_entity_unit_number] = miner
      miners[event.old_entity_unit_number] = nil
    else
      miners:new(event.new_entity)
    end
end

--Destroy attachments, then destroy miner record
function miners:die()
    if not self.entity.valid then
        self.miners[self.unit_number] = nil
        self = nil
    end
    return not self
end



return miners