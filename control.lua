require "defines"

-- Exported public API. The GUI also works by calling methods on this
-- API.
local interface = {}

-- Map of player index (int) to a boolean value. True for enabled, false
-- for disabled. This is how we keep track of which players have
-- QuickPrints mode enabled.
local enabled = {}

-- These are both the GuiElement and locale-string names for buttons in
-- the GUI.
local button_name_expand    = "quickprints-button"
local button_name_on        = "quickprints-on"
local button_name_off       = "quickprints-off"
local button_name_blueprint = "quickprints-blueprint"
local button_name_research  = "quickprints-research"
local button_name_help      = "quickprints-help"

-- Creates the equivalent non-ghost entity, placing it onto surface 1.
-- If the area is blocked then the entity will not be created.
--
-- @param ghost Entity
-- @return Entity|nil  The entity created and placed to replace the
--                     ghost, or nil if no entity was created.
--
-- Entity http://www.factorioforums.com/wiki/index.php?title=Lua/Entity
--
function make_corporeal(ghost)
  -- List of properties from:
  -- http://www.factorioforums.com/wiki/index.php?title=Lua/Surface#create_entity
  --
  -- Note that the property for "transport-belt-to-ground" is not "type"
  -- as the list may suggest. It is in fact "belt_to_ground_type" which
  -- is documented here: http://www.factorioforums.com/wiki/index.php?title=Lua/Entity#belt_to_ground_type
  --
  local properties = {}
  
  -- All entities have these properties.
  properties.name = ghost.ghost_name
  properties.position = ghost.position
  properties.direction = ghost.direction
  properties.force = ghost.force
  
  -- "LuaEntity does not contain key target"
  -- properties.target = ghost.target
  
  -- Note: we have to test the ghost_type, because if you try and access
  --       a property the ghost entity does not have then the game will
  --       crash with an error message.
  if ghost.ghost_type == "assembling-machine" then
    properties.recipe = ghost.recipe.name
  end
  if ghost.ghost_type == "container" then
    -- No way to get the container bar right now.
    -- Talked to Rseding91 and this should be in for 0.12.7
  end
  if ghost.ghost_type == "flying-text" then
    properties.text = ghost.text
    properties.color = ghost.color
  end
  if ghost.ghost_name == "smart-inserter" then
    -- Figured out these using:
    --   serpent.dump(blueprint.get_blueprint_entities())
    local conditions =
      { circuit = ghost.get_circuit_condition(1).condition
      , logistics = ghost.get_circuit_condition(2).condition
      }
    local filters = {}
    for i=1,5 do
      filters[i] = { index = i, name = ghost.get_filter(i) }
    end
    properties.conditions = conditions
    properties.filters = filters
  end
  if ghost.ghost_type == "item-entity" then
    properties.stack = ghost.stack
  end
  if ghost.ghost_name == "logistic-chest-requester" then
    -- Figured out these using:
    --   serpent.dump(blueprint.get_blueprint_entities())
    local request_filters = {}
    -- There are 10 request slots on a requester chest, starting at
    -- index 1.
    for i=1,10 do
      local slot = ghost.get_request_slot(i)
      request_filters[i] = 
        { index = i
        , name  = slot.name
        , count = slot.count
        }
    end
    properties.request_filters = request_filters
  end
  if ghost.ghost_type == "particle" then
    properties.movement = ghost.movement
    properties.height = ghost.height
    properties.vertical_speed = ghost.vertical_speed
    properties.frame_speed = ghost.frame_speed
  end
  if ghost.ghost_type == "projectile" then
    properties.speed = ghost.speed
  end
  if ghost.ghost_type == "resource" then
    properties.amount = ghost.amount
  end
  if ghost.ghost_type == "transport-belt-to-ground" then
    -- Due to bug http://www.factorioforums.com/forum/viewtopic.php?f=7&t=15496
    -- This will fail with an exception, hence the pcall. The idea is
    -- that this code begins working as soon as the bug is fixed. Until
    -- then, these transport belts will always be "input" i.e.
    -- from-ground-to-underground.
    -- Note: now there is this more general bug
    -- http://www.factorioforums.com/forum/viewtopic.php?f=7&t=15525
    pcall(function ()
      properties.belt_to_ground_type = entity.belt_to_ground_type
    end)
  end
  if ghost.ghost_type == "electric-pole" then
    -- No way to get neighbours right now (to create logic wires).
  end
  
  -- We have to make sure the entity won't collide with other objects.
  -- For example, if we don't do this the player could become trapped
  -- inside the placed object.
  -- TODO: This would be fine for any object the player can normally
  --       walk on. Not sure how to check for that.
  local surface = game.get_surface(1)
  if surface.can_place_entity(properties) then
    return surface.create_entity(properties)
  else
    return nil
  end
  
end

-- Determines if a given player_index exists. If it does not an error
-- message is printed. This is for use with the console API.
--
-- @param player_index int
-- @return bool  True if the player index is valid and False otherwise.
--
function check_player_index(player_index)
  if not game.players[player_index] then
    for _, player in pairs(game.players) do
      player.print("Invalid player index.")
      player.print(
        "To print your player index: "
        .. "/c game.local_player.print(game.local_player.index)"
      )
    player.print(
      "QuickPrints help: /c remote.call(\"qp\",\"help\","
      .. "player_index)"
    )
    end
    return false
  end
  return true
end

-- Initialises the GUI for the given player if it has not been already.
-- This adds a button to open the full GUI.
--
-- @param player Player
-- @return void
--
-- Player http://www.factorioforums.com/wiki/index.php?title=Lua/Player
--
function init_gui(player)
  if not player.gui.top[button_name_expand] then
    player.gui.top.add{ type="button"
                      , name=button_name_expand
                      , caption={button_name_expand}
                      }
  end
end

-- Opens the full GUI for the given player. If the interface is already
-- open then it is instead closed.
--
-- @param player Player
-- @return void
--
-- Player http://www.factorioforums.com/wiki/index.php?title=Lua/Player
--
function expand_gui(player)
  local frame = player.gui.left["quickprints"]
	if (frame) then
		frame.destroy()
	else
		frame = player.gui.left.add{type="frame", name="quickprints"}
		frame.add{ type="button"
             , name=button_name_on
             , caption={button_name_on}
             }
		frame.add{ type="button"
             , name=button_name_off
             , caption={button_name_off}
             }
    frame.add{ type="button"
             , name=button_name_blueprint
             , caption={button_name_blueprint}
             }
    frame.add{ type="button"
             , name=button_name_research
             , caption={button_name_research}
             }
    frame.add{ type="button"
             , name=button_name_help
             , caption={button_name_help}
             }
	end
end

-- Initialise QuickPrints for the given player.
--   - Prints QuickPrints help message.
--   - Initialises the GUI.
--
-- @param player Player
-- @return void
--
-- Player http://www.factorioforums.com/wiki/index.php?title=Lua/Player
--
function init_player(player)
  player.print(
    "QuickPrints help: /c remote.call(\"qp\",\"help\","
    .. "player_index)"
  )
  init_gui(player)
end

-- Searches through the player's main and quickbar inventories for a
-- maximal stack.
--
-- @param compare (ItemStack, ItemStack) -> int
-- @param player  Player
-- @return
--   If a maximal stack is found returns the table:
--     { inventory = Inventory   inventory the stack was found in
--     , index     = int         index of the stack in the inventory
--     , stack     = ItemStack   the maximal stack
--     }
--   Otherwise, returns nil.
--
-- The parameter "compare" compares two stacks, returning > 0 if the
-- first is greater than the second, 0 if they are equal, and < 0 if the
-- first is less than the second.
--   Example:
--   compare = function (a,b) return a.health - b.health end
--
-- ItemStack http://www.factorioforums.com/wiki/index.php?title=Lua/ItemStack
-- Inventory http://www.factorioforums.com/wiki/index.php?title=Lua/Inventory
-- Player    http://www.factorioforums.com/wiki/index.php?title=Lua/Player
--
function find_max_stack_on_player(compare, player)
  
  local inventories =
    { player.get_inventory(defines.inventory.player_main)
    , player.get_inventory(defines.inventory.player_quickbar)
    }
  local best = nil
  
  for i = 1, #inventories do
    local inventory = inventories[i]
    local result = find_max_stack(compare, inventory)
    if not (result == nil)
       and ( best == nil
             or compare(result.stack, best.stack) > 0
           )
     then
      best = { inventory = inventory
             , index     = result.index
             , stack     = result.stack
             }
     end
  end
  
  return best

end

-- Searches through an inventory for a maximal stack.
--
-- @param compare   (ItemStack, ItemStack) -> int
-- @param inventory Inventory
-- @return
--   If a maximal stack is found returns the table:
--     { index = int          index of the stack in the inventory
--     , stack = ItemStack    the maximal stack
--     }
--   Otherwise, returns nil.
--
-- The parameter "compare" compares two stacks, returning > 0 if the
-- first is greater than the second, 0 if they are equal, and < 0 if the
-- first is less than the second.
--   Example:
--   compare = function (a,b) return a.health - b.health end
--
-- ItemStack http://www.factorioforums.com/wiki/index.php?title=Lua/ItemStack
-- Inventory http://www.factorioforums.com/wiki/index.php?title=Lua/Inventory
--
function find_max_stack(compare, inventory)
  local best = nil
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack.valid_for_read
       and ( best == nil
             or compare(stack, best.stack) > 0
           )
    then
      best = { index = i
             , stack = stack
             }
    end
  end
  return best
end

-- Initialise QuickPrints for all players on game start.
--
game.on_init(function()
	for _, player in pairs(game.players) do
    init_player(player)
  end
end)

-- If a player is added to the game initialise QuickPrints for them.
--
game.on_event(defines.events.on_player_created, function (event)
  local player = game.players[event.player_index]
  init_player(player)
end)

-- Every tick, for each player that has QuickPrints mode enabled, look
-- nearby that player for ghost entities. For each ghost entity found,
-- if the player has the corresponding item in their inventory, remove
-- that item and place it over the ghost entity.
--
game.on_event(defines.events.on_tick, function()
  for _, player in pairs(game.players) do
    if not enabled[player.index] then
      return
    end
    -- Taking a guess at the maximum distance a player can place
    -- objects.
    local center = player.position
    local minCorner = {center.x - 6, center.y - 6}
    local maxCorner = {center.x + 6, center.y + 6}
    local nearbyEntities = game.get_surface(1)
      .find_entities{minCorner, maxCorner}
    for _, entity in pairs(nearbyEntities) do
      -- For what "entity.valid" does see:
      -- http://www.factorioforums.com/forum/viewtopic.php?f=23&t=15530
      if entity.valid and entity.name == "entity-ghost" then
        -- Look for the stack that has the most health and use this to
        -- place the ghost entity.
        local result =
          find_max_stack_on_player(
            function (a,b)
              if a.name == entity.ghost_name
                 and b.name == entity.ghost_name
              then
                return a.health - b.health
              elseif a.name == entity.ghost_name then
                return 1
              else
                return -1
              end
            end
          , player
          )
        if not (result == nil)
           and result.stack.name == entity.ghost_name
           and result.stack.count > 0 then
          local body = make_corporeal(entity)
          if not (body == nil) then
            -- Remembering to set the health of the placed entity. The
            -- stack health is a percentage of the max health.
            body.health = body.health * result.stack.health
            result.stack.count = result.stack.count - 1
          end
        end
      end
    end
  end
end)

-- Respond to events on the GUI. This dispatches to public API calls.
--
game.on_event(defines.events.on_gui_click, function(event)
  local player_index = event.element.player_index
	local player = game.players[player_index]
	local name = event.element.name
  if (name == button_name_expand) then
		expand_gui(player)
	end
  if (name == button_name_on) then
    interface.on(player_index)
  end
  if (name == button_name_off) then
    interface.off(player_index)
  end
  if (name == button_name_blueprint) then
    interface.blueprint(player_index)
  end
  if (name == button_name_research) then
    interface.research()
  end
  if (name == button_name_help) then
    interface.help(player_index)
  end
end)

------------------------------------------------------------------------
-- Public API ----------------------------------------------------------
------------------------------------------------------------------------

-- Initialises QuickPrints for the player. This should have already
-- been done automatically, but in case something goes awry this can
-- be called manually.
--
-- @param player_index int
-- @return void
--
interface.init = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  local player = game.players[player_index]
  player.print("Initialising QuickPrints for player " .. player_index)
  init_player(player)
end

-- Prints help information for the QuickPrints mod to the player.
--
-- @param player_index int
-- @return void
--
interface.help = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  local player = game.players[player_index]
  player.print("-- QuickPrints help ---------------------------------")
  player.print(
    "/c remote.call(\"qp\",\"help\",player_index)             "
    .. "Print this help information to the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"toggle\",player_index)           "
    .. "Toggles QuickPrints mode for the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"on\",player_index)               "
    .. "Enables QuickPrints mode for the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"off\",player_index)              "
    .. "Disables QuickPrints mode for the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"research\",player_index)         "
    .. "Unlocks automated-construction research, necessary to place "
    .. "ghost objects, for all player forces."
  )
  player.print(
    "/c remote.call(\"qp\",\"blueprint\",player_index)        "
    .. "Gives a blueprint to the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"init\",player_index)             "
    .. "Initialises QuickPrints for the player."
  )
  player.print("-----------------------------------------------------")
end

-- Enable QuickPrints mode for the player.
--
-- @param player_index int
-- @return void
interface.on = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  enabled[player_index] = true
  interface.state(player_index)
end

-- Disable QuickPrints mode for the player.
--
-- @param player_index int
-- @return void
--
interface.off = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  enabled[player_index] = false
  interface.state(player_index)
end

-- Toggle QuickPrints mode for the player. This works conveniently with
-- your console command history.
--
-- @param player_index int
-- @return void
--
interface.toggle = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  enabled[player_index] = not enabled[player_index]
  interface.state(player_index)
end

-- Prints, to the respective player only, if QuickPrints mode is enabled
-- for them or not.
--
-- @param player_index int
-- @return void
--
interface.state = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  if enabled[player_index] then
    game.players[player_index].print(
      "QuickPrints mode enabled for player " .. player_index
    )
  else
    game.players[player_index].print(
      "QuickPrints mode disabled for player " .. player_index
    )
  end
end

-- Unlocks automated-construction research, necessary to place ghost
-- objects, for all player forces.
--
-- @return void
--
interface.research = function ()
  for _, player in pairs(game.players) do
    player.force.technologies["automated-construction"]
      .researched = true
    player.print(
      "QuickPrints has unlocked 'Automated Construction' "
      .. "research."
    )
  end
end

-- Gives the player a blueprint.
--
-- @param player_index int
-- @return void
--
interface.blueprint = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  local player = game.players[player_index]
  player.insert{
      name  = "blueprint"
    , count = 1
  }
  player.print("QuickPrints has given you a blueprint.")
end

remote.add_interface("qp", interface)