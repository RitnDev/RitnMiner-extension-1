local miners = require("classes.AaiMiner")
--------------------------------------------------------------------------------

local function mine_subsurface_area(miner) 


end


local function mine_resource(miner, resource, required_fluid)
    -- required fluid is {name=fluid_name, per_cycle=fluid_per_cycle} or nil
    local variant = miner.variants[miner.name]
    local proto = resource.prototype

    -- TODO factor in modules
    -- TODO factor in productivity research
    -- TODO implement mineable_properties .mining_trigger https://lua-api.factorio.com/latest/Concepts.html#Trigger
    local mining_speed = base_mining_speed * variant.mining_speed * global["vehicle-mining-multiplier"] / 100
    --local mining_power = variant.mining_power

    --[[
    resource / mining properties
    proto.mineable_properties.miningtime -- the time to mine a cycle
    proto.infinite_resource -- is it infinite
    proto.minimum_resource_amount -- ?
    proto.normal_resource_amount -- sets the normal amount for resourecs that slowly deplete and reduce the effective mining speed
        mining speed multiplier = resource.amount / proto.normal_resource_amount
        -- only applies to basic-fluid?
    proto.infinite_depletion_resource_amount aka raw:infinite_depletion_amount	Every time this infinite resource 'ticks' down it is reduced by this amount.
      -- cruse oil is 10
    proto.resource_category -- "basic-solid" or "basic-fluid"

    ]]--

    if miner.stopped_on_fluid[resource.name] then
      miner.stopped_on_fluid[resource.name] = nil
      barrel_fluids(miner)
      if miner.stopped_on_fluid[resource.name] then
        return miner
      end
    end


    -- (Mining power - Mining hardness) * Mining speed / Mining time = Production rate (in resource/sec)
    --local mining_rate_per_sec = (mining_power - proto.mineable_properties.hardness ) * mining_speed / (proto.mineable_properties.miningtime or 1)
    local mining_rate_per_sec = mining_speed / proto.mineable_properties.mining_time
    if proto.resource_category == "basic-fluid" and proto.normal_resource_amount and proto.normal_resource_amount > 1 then
        -- normal on a resource should mean that the output is at 100% at normal amount
        -- if the amount is different the the yield is different
        mining_rate_per_sec = mining_rate_per_sec * resource.amount / proto.normal_resource_amount
    end
    miner.mining_progress = (miner.mining_progress or 0) + mining_rate_per_sec / 60 * global["vehicle-mining-interval"]

    -- consume energy
    miner.entity.burner.remaining_burning_fuel = miner.entity.burner.remaining_burning_fuel - variant.mining_energy_use / 60 * global["vehicle-mining-interval"]

    -- add pollution
    miner.entity.surface.pollute(miner.entity.position, variant.mining_pollution * global["vehicle-mining-interval"])

    mining_particles(miner, proto.mineable_properties.miningparticle, 1)
    -- mining results:
    -- can't exceed fluid limit
    if miner.mining_progress >= 1 then
        local complete_cycles = math.floor(miner.mining_progress)
        if required_fluid then
            local required_fluid_available = get_fluid_available(miner, required_fluid.name)
            complete_cycles = math.min(complete_cycles, math.floor(required_fluid_available / required_fluid.per_cycle))
        end
        -- productivity
        miner.mining_bonus = (miner.mining_bonus or 0) + complete_cycles * (miner.entity.force.mining_drill_productivity_bonus or 0)
        miner.mining_progress = miner.mining_progress - complete_cycles


        if required_fluid then
            consume_fluid(miner, required_fluid.name, required_fluid.per_cycle * complete_cycles)
        end
        -- insert the products
        insert_products(miner, proto.mineable_properties.products, complete_cycles)
        if miner.mining_bonus >= 1 then
          insert_products(miner, proto.mineable_properties.products, math.floor(miner.mining_bonus))
          miner.mining_bonus = miner.mining_bonus -  math.floor(miner.mining_bonus)
        end

        -- barrel up fluids if possible
        barrel_fluids(miner)

        -- reduce resource amount
        local amount_remaining = resource.amount

        if proto.infinite_resource == true then

            if proto.infinite_depletion_resource_amount and proto.infinite_depletion_resource_amount > 0 then
              amount_remaining = amount_remaining - complete_cycles * proto.infinite_depletion_resource_amount
            else
              amount_remaining = amount_remaining - complete_cycles
            end

            if proto.minimum_resource_amount and proto.minimum_resource_amount > 0 then
              amount_remaining = math.max(amount_remaining, proto.minimum_resource_amount)
            end

        else
          amount_remaining = amount_remaining - complete_cycles
        end

        if amount_remaining >= 1 then
            resource.amount = amount_remaining
        else
            resource.amount = 1
            resource.deplete()
        end

    end

    return miner
end

local function mine_subsurface_area(miner)
  -- 20
    if (game.tick + miner.entity.unit_number) % global["vehicle-mining-interval"] == 0 then

        local variant = miner.variants[miner.name]
        local area = {
            {miner.entity.position.x - variant.mining_range, miner.entity.position.y - variant.mining_range},
            {miner.entity.position.x + variant.mining_range, miner.entity.position.y + variant.mining_range}
        }
        local try_resources = miner.entity.surface.find_entities_filtered{type = "resource", area = area}

        local resources = {}
        for _, resource in pairs(try_resources) do
          local proto = Prototypes.entity_prototype(resource.name)
          if not global.disallowed_resource_categories[proto.resource_category] then
            table.insert(resources, resource)
          end
        end

        table.sort(
            resources,
            function(a,b)
                -- choose basic-solid over basic-fluid
                local ap = Prototypes.entity_prototype(a.name)
                local bp = Prototypes.entity_prototype(b.name)
                if ap.resource_category ~= b.prototype.resource_category then
                  return ap.resource_category > b.prototype.resource_category
                end

                -- choose coal over non-coal
                if a.name == "coal" and b.name == "coal" then
                  return a.amount > b.amount
                elseif a.name == "coal" then
                  return true
                elseif b.name == "coal" then
                  return false
                end
                -- choose higher amount
                return a.amount > b.amount
            end
        )

        --local exclude_types = {}
        local exclude_types = table.deepcopy(global.disallow_resources)
        -- mine higher value resource chunks first, more effective if only a small portion of tiles are scanned
        for _, resource in ipairs(resources) do
            if resource.minable then
                local proto = resource.prototype
                if proto.mineable_properties then
                    -- make sure all products can be inserted
                    if not exclude_types[resource.name] then
                        local can_insert = true
                        if proto.mineable_properties.products then -- fix for dirty ores
                          for _, product in pairs(proto.mineable_properties.products) do
                              if product.type == "item" then
                                if not miner.entity.can_insert(product.name) then
                                  can_insert = false
                                  exclude_types[resource.name] = true
                                  break
                                end
                              end
                          end
                        end
                        if can_insert then
                            if proto.mineable_properties
                              and proto.mineable_properties.minable
                              and proto.mineable_properties.required_fluid
                              and proto.mineable_properties.fluid_amount > 0 then
                                -- fluid is required
                                local fluid_name = proto.mineable_properties.required_fluid
                                local fluid_per_cycle = proto.mineable_properties.fluid_amount / fluid_efficiency
                                if is_fluid_available(miner, fluid_name, fluid_per_cycle) then
                                    -- there is enough fluid for at least 1 cycle
                                    -- this can be mined
                                    mine_resource(miner, resource, {name=fluid_name, per_cycle=fluid_per_cycle})
                                    break
                                else -- can't mine becuase of fluid requirement, move on to next resource
                                  exclude_types[resource.name] = true
                                end
                            else
                                -- fluid is not required
                                -- this can be mined
                                mine_resource(miner, resource, nil)
                                break
                            end
                        end
                    end
                end
            end
        end -- end for

    end

    return miner
end


--------------------------------------------------------------------------------

--local function on_tick(event)
local function on_tick()

    for _, miner in pairs(miners.miners) do
        if miner.entity.valid and ( (not global["vehicle-mining-requires-movement"]) or (miner.entity.speed > 0.001 or miner.entity.speed < -0.001)) then
            if miner.entity.burner.remaining_burning_fuel > 0 then
               
                if not miner.inventory_buffer then
                  mine_subsurface_area(miner)
                end

            end
        else -- not miner.entity.valid
            miner:die()
        end

    end
end

-------------------------------------------------------------------------------
--[[INIT]]--
-------------------------------------------------------------------------------

local function on_configuration_changed()
    global["vehicle-mining-multiplier"] = settings.global["vehicle-mining-multiplier"].value
    global["vehicle-mining-interval"] = settings.global["vehicle-mining-interval"].value
    global["vehicle-mining-requires-movement"] = settings.global["vehicle-mining-requires-movement"].value
    global["vehicle-collection-interval"] = settings.global["vehicle-collection-interval"].value
end
script.on_configuration_changed(on_configuration_changed)

local function on_init()
    global["vehicle-mining-multiplier"] = settings.global["vehicle-mining-multiplier"].value
    global["vehicle-mining-interval"] = settings.global["vehicle-mining-interval"].value
    global["vehicle-mining-requires-movement"] = settings.global["vehicle-mining-requires-movement"].value
    global["vehicle-collection-interval"] = settings.global["vehicle-collection-interval"].value
end
script.on_init(on_init)
-------------------------------------------------------------------------------
--[[EVENTS]]--
-------------------------------------------------------------------------------
script.on_event(defines.events.on_tick, on_tick)