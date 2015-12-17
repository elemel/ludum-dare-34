local Character = require "Character"
local Terrain = require "Terrain"

local Score = {}
Score.__index = Score

function Score.new(args)
  local score = {
    game = args.game,
    fontsBySize = {},
    time = 0,
  }

  score = setmetatable(score, Score)

  score.game.updateHandlers.score[score] = Score.update
  score.game.drawHandlers.score[score] = Score.draw

  score:initTerrain()

  score.player = Character.new({
    game = score.game,
    x = 1, y = 0,
    width = 0.75, height = 1.25,
  })

  return score
end

function Score:initTerrain()
  self.terrain = Terrain.new({
    game = self.game,
    width = 64, height = 16,
    tileWidth = 0.5, tileHeight = 0.5,
  })

  self.terrain:setTiles(0, 15, 66, 2, "stone")
  self.terrain:setTiles(16, 9, 1, 7, "stone")
  self.terrain:setTiles(12, 1, 1, 10, "stone")
end

function Score:destroy()
  self.game.drawHandlers.score[self] = nil
  self.game.updateHandlers.score[self] = nil
end

function Score:update(dt)
  self.time = self.time + dt

  self.message = nil

  if self.time < 2 then
    self.message = "LEVEL 1"
  end

  if self.player.box.x + 0.5 * self.player.box.width < 0.5 then
    self.message = "GAME OVER"
  end

  if self.player.box.y - 0.5 * self.player.box.height > self.terrain.height + 0.5 then
    self.message = "GAME OVER"
  end
end

function Score:draw()
  self:drawMessage()
end

function Score:drawMessage()
  if self.message then
    local width, height = love.window.getDimensions()

    love.graphics.push()
    love.graphics.reset()

    local fontSize = 0.125 * height
    local font = self:getFont(fontSize)

    local oldFont = love.graphics.getFont()
    love.graphics.setFont(font)
    love.graphics.printf(self.message, 0, 0.5 * height - 0.5 * fontSize, width, "center")
    love.graphics.setFont(oldFont)

    love.graphics.pop()
  end
end

function Score:getFont(size)
  size = math.floor(size + 0.5)
  local font = self.fontsBySize[size]

  if not font then
    font = love.graphics.newFont(size)
    self.fontsBySize[size] = font
  end

  return font
end

return Score
