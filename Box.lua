local Box = {}
Box.__index = Box

function Box.new(args)
  local box = {
    x = args.x or 0, y = args.y or 0,
    width = args.width or 1, height = args.height or 1,
    velocityX = args.velocityX or 0, velocityY = args.velocityY or 0,
  }

  return setmetatable(box, Box)
end

function Box:intersectsBox(x, y, width, height)
  local leftDistance = (self.x - 0.5 * self.width) - (x + 0.5 * width)
  local rightDistance = (x - 0.5 * width) - (self.x + 0.5 * self.width)

  local upDistance = (self.y - 0.5 * self.height) - (y + 0.5 * height)
  local downDistance = (y - 0.5 * height) - (self.y + 0.5 * self.height)

  return leftDistance < 0 and rightDistance < 0 and upDistance < 0 and downDistance < 0
end

function Box:collideBox(x, y, width, height, velocityX, velocityY)
  local leftDistance = (self.x - 0.5 * self.width) - (x + 0.5 * width)
  local rightDistance = (x - 0.5 * width) - (self.x + 0.5 * self.width)

  local upDistance = (self.y - 0.5 * self.height) - (y + 0.5 * height)
  local downDistance = (y - 0.5 * height) - (self.y + 0.5 * self.height)

  if leftDistance < 0 and rightDistance < 0 and upDistance < 0 and downDistance < 0 then
    if math.max(leftDistance, rightDistance) > math.max(upDistance, downDistance) then
      if leftDistance > rightDistance then
        self.x = self.x - leftDistance
        self.velocityX = math.max(self.velocityX, velocityX)
        return "left"
      else
        self.x = self.x + rightDistance
        self.velocityX = math.min(self.velocityX, velocityX)
        return "right"
      end
    else
      if upDistance > downDistance then
        self.y = self.y - upDistance
        self.velocityY = math.max(self.velocityY, velocityY)
        return "up"
      else
        self.y = self.y + downDistance
        self.velocityY = math.min(self.velocityY, velocityY)
        return "down"
      end
    end
  end

  return nil
end

return Box
