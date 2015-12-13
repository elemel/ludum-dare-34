local Block = {}
Block.__index = Block

function Block.new(args)
  local block = {
    x = args.x or 0, y = args.y or 0,
    width = args.width or 1, height = args.height or 1,
    velocityX = args.velocityX or 0, velocityY = args.velocityY or 0,

    collisions = {
      left = false, right = false,
      up = false, down = false,
    },
  }

  return setmetatable(block, Block)
end

function Block:clearCollisions()
  for direction, _ in pairs(self.collisions) do
    self.collisions[direction] = false
  end
end

function Block:collideBox(x, y, width, height, velocityX, velocityY)
  local leftDistance = (self.x - 0.5 * self.width) - (x + 0.5 * width)
  local rightDistance = (x - 0.5 * width) - (self.x + 0.5 * self.width)

  local upDistance = (self.y - 0.5 * self.height) - (y + 0.5 * height)
  local downDistance = (y - 0.5 * height) - (self.y + 0.5 * self.height)

  if leftDistance < 0 and rightDistance < 0 and upDistance < 0 and downDistance < 0 then
    if math.max(leftDistance, rightDistance) > math.max(upDistance, downDistance) then
      if leftDistance > rightDistance then
        self.x = self.x - leftDistance
        self.velocityX = math.max(self.velocityX, velocityX)
        self.collisions.left = true
        return "left"
      else
        self.x = self.x + rightDistance
        self.velocityX = math.min(self.velocityX, velocityX)
        self.collisions.right = true
        return "right"
      end
    else
      if upDistance > downDistance then
        self.y = self.y - upDistance
        self.velocityY = math.max(self.velocityY, velocityY)
        self.collisions.up = true
        return "up"
      else
        self.y = self.y + downDistance
        self.velocityY = math.min(self.velocityY, velocityY)
        self.collisions.down = true
        return "down"
      end
    end
  end

  return nil
end

return Block
