local Camera = require "Camera"
local Fade = require "Fade"
local Game = require "Game"
local Player = require "Player"
local Terrain = require "Terrain"

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
    updatePasses = {"player", "fade", "camera"},
    drawPasses = {"camera", "terrain", "player", "fade"},
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
    scale = 0.125,
  })

  local terrain = Terrain.new({
    game = screen.game,
  })

  terrain:setTile(-3, -1, "stone")
  terrain:setTile(-3, 0, "stone")
  terrain:setTile(-2, 0, "stone")
  terrain:setTile(-1, 0, "stone")
  terrain:setTile(0, 0, "stone")
  terrain:setTile(1, 0, "stone")
  terrain:setTile(2, 0, "stone")
  terrain:setTile(3, 0, "stone")
  terrain:setTile(3, 0, "stone")
  terrain:setTile(4, 0, "stone")
  terrain:setTile(4, -1, "stone")
  terrain:setTile(4, -2, "stone")
  terrain:setTile(4, -3, "stone")
  terrain:setTile(4, -4, "stone")
  terrain:setTile(4, -5, "stone")
  terrain:setTile(4, -6, "stone")
  terrain:setTile(4, -7, "stone")
  terrain:setTile(3, -7, "stone")
  terrain:setTile(2, -7, "stone")
  terrain:setTile(1, -7, "stone")

  Player.new({
    game = screen.game,
    x = 0, y = -10,
    width = 2, height = 3,
  })

  Fade.new({
    game = screen.game,
    time1 = 0, time2 = 2,
    color1 = {0, 0, 0, 255}, color2 = {0, 0, 0, 0},
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
