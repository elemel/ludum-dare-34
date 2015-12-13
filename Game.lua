local Game = {}
Game.__index = Game

function Game.new(args)
  args = args or {}

  local game = {
    entitiesByName = {},

    updatePasses = args.updatePasses or {},
    updateHandlers = {},

    drawPasses = args.drawPasses or {},
    drawHandlers = {},

    images = {},
  }

  for _, pass in pairs(game.updatePasses) do
    game.updateHandlers[pass] = {}
  end

  for _, pass in pairs(game.drawPasses) do
    game.drawHandlers[pass] = {}
  end

  return setmetatable(game, Game)
end

function Game:update(dt)
  for _, pass in ipairs(self.updatePasses) do
    for entity, handler in pairs(self.updateHandlers[pass]) do
      handler(entity, dt)
    end
  end
end

function Game:draw()
  for _, pass in ipairs(self.drawPasses) do
    for entity, handler in pairs(self.drawHandlers[pass]) do
      handler(entity)
    end
  end
end

return Game
