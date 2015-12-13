local Camera = {}
Camera.__index = Camera

function Camera.new(args)
  local camera = {
    game = args.game,
    x = args.x or 0, y = args.y or 0,
    scale = args.scale or 1,
  }

  camera.game.drawHandlers.camera[camera] = Camera.draw
  camera.game.entitiesByName.camera = camera

  return setmetatable(camera, Camera)
end

function Camera:draw()
  local width, height = love.window.getDimensions()
  local scale = 0.5 * self.scale * height
  love.graphics.translate(0.5 * width, 0.5 * height)
  love.graphics.scale(scale)
  love.graphics.translate(-self.x, -self.y)
  love.graphics.setLineWidth(1 / scale)
end

return Camera
