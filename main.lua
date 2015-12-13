local GameScreen = require "GameScreen"

function love.load()
  love.window.setTitle("Ludum Dare 34")
  love.window.setMode(800, 600, {
    fullscreen = true,
    fullscreentype = "desktop",
    resizable = "true",
  })

  screen = GameScreen.new()
end

function love.update(dt)
  screen:update(dt)
end

function love.draw()
  screen:draw()
end
