local Camera = require "Camera"
local Fade = require "Fade"
local Game = require "Game"
local Score = require "Score"

local GameScreen = {}
GameScreen.__index = GameScreen

local function loadImage(path)
  local image = love.graphics.newImage(path)
  image:setFilter("nearest")
  return image
end

function GameScreen.new(args)
  local screen = {}

  screen.game = Game.new({
    updatePasses = {"score", "character", "fade", "camera"},
    drawPasses = {"camera", "terrain", "character", "fade", "score"},
  })

  screen.game.images.tiles = {
    rubble = loadImage("resources/images/tiles/rubble.png"),
    stone = loadImage("resources/images/tiles/stone.png"),
  }

  screen.game.images.skins = {}

  screen.game.images.skins.ettin = {
    stand = loadImage("resources/images/skins/ettin/stand.png"),
  }

  Camera.new({
    game = screen.game,
    scale = 0.25,
  })

  Fade.new({
    game = screen.game,
    time1 = 0, time2 = 2,
    color1 = {0, 0, 0, 255}, color2 = {0, 0, 0, 0},
  })

  Score.new({
    game = screen.game,
  })

  return setmetatable(screen, GameScreen)
end

function GameScreen:update(dt)
  self.game:update(dt)
end

function GameScreen:draw()
  self.game:draw()
end

return GameScreen
