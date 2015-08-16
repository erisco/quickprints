require "defines"

-- Map of player index to a boolean value. True for enabled, false for
-- disabled. This is how we keep track of which players have QuickPrints
-- mode enabled.
local enabled = {}

-- Creates the equivalent non-ghost entity, placing it onto surface 1.
-- If the area is blocked then the entity will not be created.
--
-- Returns true if the non-ghost entity was placed and false otherwise.
--
function make_corporeal(ghost)
  -- List of properties from:
  -- http://www.factorioforums.com/wiki/index.php?title=Lua/Surface#create_entity
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
    properties.bar = ghost.bar
  end
  if ghost.ghost_type == "flying-text" then
    properties.text = ghost.text
    properties.color = ghost.color
  end
  if ghost.ghost_name == "smart-inserter" then
    properties.conditions = ghost.conditions
    properties.filters = ghost.filters
  end
  if ghost.ghost_type == "item-entity" then
    properties.stack = ghost.stack
  end
  if ghost.ghost_type == "logistic-container" then
    properties.requestfilters = ghost.requestfilters
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
    properties.type = ghost.ghost_type
  end
  
  -- We have to make sure the entity won't collide with other objects.
  -- For example, if we don't do this the player could become trapped
  -- inside the placed object.
  local surface = game.get_surface(1)
  if surface.can_place_entity(properties) then
    surface.create_entity(properties)
    return true
  else
    return false
  end
  
end

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

-- Print help information on game start.
game.on_init(function()
	for _, player in pairs(game.players) do  
    player.print(
      "QuickPrints help: /c remote.call(\"qp\",\"help\","
      .. "player_index)"
    )
  end
end)

-- Every tick, for each player that has QuickPrints mode enabled, look
-- nearby that player for ghost entities. For each ghost entity found,
-- if the player has the corresponding item in their inventory, remove
-- that item and place it over the ghost entity.
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
      if entity.name == "entity-ghost" then
        local stack = {
            name  = entity.ghost_name
          , count = 1
        }
        if player.get_item_count(stack.name) >= stack.count then
          if make_corporeal(entity) then
            player.remove_item(stack)
          end
        end
      end
    end
  end
end)

------------------------------------------------------------------------
-- Public API ----------------------------------------------------------
------------------------------------------------------------------------

local interface = {}

-- Prints help information for the QuickPrints mod to the player.
interface.help = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  local player = game.players[player_index]
  player.print("-- QuickPrints help ---------------------------------")
  player.print(
    "/c remote.call(\"qp\",\"help\",player_index)        "
    .. "Print this help information to the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"toggle\",player_index)        "
    .. "Toggles QuickPrints mode for the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"on\",player_index)        "
    .. "Enables QuickPrints mode for the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"off\",player_index)        "
    .. "Disables QuickPrints mode for the player."
  )
  player.print(
    "/c remote.call(\"qp\",\"research\",player_index)        "
    .. "Unlocks automated-construction research, necessary to place "
    .. "ghost objects, for all player forces."
  )
  player.print(
    "/c remote.call(\"qp\",\"blueprint\",player_index)        "
    .. "Gives a blueprint to the player."
  )
  player.print("-----------------------------------------------------")
end

-- Enable QuickPrints mode for the player.
interface.on = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  enabled[player_index] = true
  interface.state(player_index)
end

-- Disable QuickPrints mode for the player.
interface.off = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  enabled[player_index] = false
  interface.state(player_index)
end

-- Toggle QuickPrints mode for the player. This works conveniently with
-- your console command history.
interface.toggle = function (player_index)
  if not check_player_index(player_index) then
    return
  end
  enabled[player_index] = not enabled[player_index]
  interface.state(player_index)
end

-- Prints, to the respective player only, if QuickPrints mode is enabled
-- for them or not.
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