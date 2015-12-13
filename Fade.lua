local common = require "common"

local Fade = {}
Fade.__index = Fade

function Fade.new(args)
  local fade = {
    game = args.game,

    time = args.time or 0,
    time1 = args.time1 or 0,
    time2 = args.time2 or 1,

    color1 = args.color1 or {0, 0, 0, 0},
    color2 = args.color2 or {0, 0, 0, 255},
  }

  fade.game.updateHandlers.fade[fade] = Fade.update
  fade.game.drawHandlers.fade[fade] = Fade.draw

  return setmetatable(fade, Fade)
end

function Fade:destroy()
  self.game.drawHandlers.fade[self] = nil
  self.game.updateHandlers.fade[self] = nil
end

function Fade:update(dt)
  self.time = self.time + dt
end

function Fade:draw()
  local width, height = love.window.getDimensions()

  love.graphics.push()
  love.graphics.reset()

  local r1, g1, b1, a1 = unpack(self.color1)
  local r2, g2, b2, a2 = unpack(self.color2)

  local t = common.smoothstep(self.time1, self.time2, self.time)

  local r = common.mix(r1, r2, t)
  local g = common.mix(g1, g2, t)
  local b = common.mix(b1, b2, t)
  local a = common.mix(a1, a2, t)

  love.graphics.setColor(r, g, b, a)
  love.graphics.rectangle("fill", 0, 0, width, height)
  love.graphics.setColor(255, 255, 255, 255)

  love.graphics.pop()
end

return Fade
