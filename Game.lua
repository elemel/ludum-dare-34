local Game = {}
Game.__index = Game

function Game.new(args)
  args = args or {}

  local game = {
    dt = 0,
    time = 0,
    minDt = args.minDt or 1 / 120, maxDt = args.maxDt or 1 / 30,

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
  self.time = self.time + dt
  self.dt = self.dt + dt

  if self.dt > self.minDt then
    local dt = math.min(self.dt, self.maxDt)
    self.dt = math.min(self.dt - dt, self.maxDt)

    for _, pass in ipairs(self.updatePasses) do
      for entity, handler in pairs(self.updateHandlers[pass]) do
        handler(entity, dt)
      end
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
