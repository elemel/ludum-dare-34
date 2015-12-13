local common = require "common"
local Block = require "Block"

local Player = {}
Player.__index = Player

function Player.new(args)
  local player = {
    game = args.game,
    state = "stand",
    direction = args.direction or 1,

    inputs = {
      left = false, right = false,
    },

    oldInputs = {
      left = false, right = false,
    },

    standAcceleration = args.standAcceleration or 12,
    fallAcceleration = args.fallAcceleration or 16,
    dropAcceleration = args.dropAcceleration or 24,

    walkVelocity = args.walkVelocity or 6,
    walkAcceleration = args.walkAcceleration or 12,

    highJumpVelocity = args.highJumpVelocity or 12,
    lowJumpVelocity = args.lowJumpVelocity or 6,

    glideVelocity = args.glideVelocity or 3,
    glideAcceleration = args.glideAcceleration or 12,

    climbAcceleration = args.climbAcceleration or 12,
    digTime = args.digTime or 0.5,

    digFlags = {
      left = false, right = false,
      up = false, down = false,
    },

    currentDigTime = 0,
  }

  player.block = Block.new({
    x = args.x, y = args.y,
    width = args.width, height = args.height,
    velocityX = args.velocityX, velocityY = args.velocityY,
  })

  player.game.updateHandlers.player[player] = Player.update
  player.game.updateHandlers.camera[player] = Player.updateCamera
  player.game.drawHandlers.player[player] = Player.draw

  return setmetatable(player, Player)
end

function Player:destroy()
  self.game.drawPasses.player[self] = nil
  self.game.updateHandlers.camera[self] = nil
  self.game.updateHandlers.player[self] = nil
end

function Player:update(dt)
  self:updateInput()
  self:transition()
  self:control(dt)
  self:collide()
end

function Player:updateInput()
  self.oldInputs.left = self.inputs.left
  self.oldInputs.right = self.inputs.right

  self.inputs.left = love.keyboard.isDown("left")
  self.inputs.right = love.keyboard.isDown("right")
end

function Player:updateCamera(dt)
  local camera = self.game.entitiesByName.camera
  camera.x, camera.y = self.block.x, self.block.y
end

function Player:transition()
  if self.state == "drop" then
    self:transitionDrop()
  elseif self.state == "fall" then
    self:transitionFall()
  elseif self.state == "climb" then
    self:transitionClimb()
  elseif self.state == "jump" then
    self:transitionJump()
  elseif self.state == "stand" then
    self:transitionStand()
  elseif self.state == "walk" then
    self:transitionWalk()
  end
end

function Player:transitionDrop()
  if self.block.collisions.down then
    self.state = "stand"
    self.digFlags.down = false
    return
  end

  if not (self.inputs.left and self.inputs.right) then
    self.state = "fall"
    self.digFlags.down = false
    return
  end
end

function Player:transitionFall()
  if self.block.collisions.down then
    self.state = "stand"
    return
  end

  if self.block.collisions.left or self.block.collisions.right then
    self.state = "climb"
    return
  end

  if (self.inputs.right and self.inputs.left) and not (self.oldInputs.right and self.oldInputs.left) then
    self.state = "drop"
    self.digFlags.down = true
  end
end

function Player:transitionClimb()
  if self.block.collisions.down then
    self.state = "stand"
    return
  end

  if not (self.block.collisions.left or self.block.collisions.right) then
    self.state = "fall"
    return
  end

  if self.inputs.left and self.inputs.right then
    self:jump()
    self.direction = -self.direction
    self.block.velocityX = self.direction * self.glideVelocity
    self.state = "jump"
    return
  end
end

function Player:transitionJump()
  if self.block.collisions.down then
    self.state = "stand"
    self.digFlags.up = false
    return
  end

  if self.block.collisions.up then
    self.state = "fall"
    self.digFlags.up = false
    return
  end

  if not (self.inputs.right and self.inputs.left) then
    self.state = "fall"
    self.block.velocityY = math.max(self.block.velocityY, -self.lowJumpVelocity)
    self.digFlags.up = false
    return
  end
end

function Player:transitionStand()
  if not self.block.collisions.down then
    self.state = "fall"
    return
  end

  if (self.inputs.right and self.inputs.left) and not (self.oldInputs.right and self.oldInputs.left) then
    self:jump()
    self.state = "jump"
    return
  end

  if self.inputs.left ~= self.inputs.right then
    self.state = "walk"
    return
  end
end

function Player:transitionWalk()
  if not self.block.collisions.down then
    self.state = "fall"
    return
  end

  if (self.inputs.right and self.inputs.left) and not (self.oldInputs.right and self.oldInputs.left) then
    self:jump()
    self.state = "jump"
    return
  end

  if self.inputs.left == self.inputs.right then
    self.state = "stand"
    return
  end
end

function Player:control(dt)
  if self.state == "drop" then
    self:controlDrop(dt)
  elseif self.state == "fall" then
    self:controlFall(dt)
  elseif self.state == "climb" then
    self:controlClimb(dt)
  elseif self.state == "jump" then
    self:controlJump(dt)
  elseif self.state == "stand" then
    self:controlStand(dt)
  elseif self.state == "walk" then
    self:controlWalk(dt)
  end
end

function Player:controlDrop(dt)
  self.block.velocityY = self.block.velocityY + self.dropAcceleration * dt
  self:updatePosition(dt)
end

function Player:controlFall(dt)
  self:turn()
  self:fall(dt)
  self:glide(dt)
  self:updatePosition(dt)
end

function Player:controlClimb(dt)
  self:turn()
  self:glide(dt)

  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)
  local velocityError = -self.block.velocityY

  self.block.velocityY = (self.block.velocityY + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.climbAcceleration * dt))

  local direction = (inputX == 1) and "right" or "left"

  if self.block.collisions[direction] then
    self.currentDigTime = self.currentDigTime + dt

    if self.currentDigTime > self.digTime then
      self.digFlags[direction] = true
      self.currentDigTime = 0
    end
  else
    self.currentDigTime = 0
  end

  self:updatePosition(dt)
end

function Player:controlJump(dt)
  self:turn()
  self:fall(dt)
  self:glide(dt)
  self:updatePosition(dt)
end

function Player:controlStand(dt)
  self:fall(dt)

  local velocityError = -self.block.velocityX

  self.block.velocityX = (self.block.velocityX + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.standAcceleration * dt))

  self:updatePosition(dt)
end

function Player:controlWalk(dt)
  self:turn()
  self:fall(dt)

  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)
  local targetVelocity = inputX * self.walkVelocity
  local velocityError = targetVelocity - self.block.velocityX

  self.block.velocityX = (self.block.velocityX + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.walkAcceleration * dt))

  local direction = (inputX == 1) and "right" or "left"

  if self.block.collisions[direction] then
    self.currentDigTime = self.currentDigTime + dt

    if self.currentDigTime > self.digTime then
      self.digFlags[direction] = true
      self.currentDigTime = 0
    end
  else
    self.currentDigTime = 0
  end

  self:updatePosition(dt)
end

function Player:turn()
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)

  if inputX ~= 0 then
    self.direction = inputX
  end
end

function Player:fall(dt)
  self.block.velocityY = self.block.velocityY + self.fallAcceleration * dt
end

function Player:glide(dt)
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)

  if inputX ~= 0 then
    local targetVelocity = inputX * math.max(self.glideVelocity, inputX * self.block.velocityX)
    local velocityError = targetVelocity - self.block.velocityX

    self.block.velocityX = (self.block.velocityX + common.sign(velocityError) *
      math.min(math.abs(velocityError), self.glideAcceleration * dt))
  end
end

function Player:jump()
  self.block.velocityY = -self.highJumpVelocity
  self.digFlags["up"] = true
end

function Player:updatePosition(dt)
  self.block.x = self.block.x + self.block.velocityX * dt
  self.block.y = self.block.y + self.block.velocityY * dt
end

function Player:collide()
  self.block:clearCollisions()

  local x1 = math.floor(self.block.x - 0.5 * self.block.width)
  local y1 = math.floor(self.block.y - 0.5 * self.block.height)

  local x2 = math.floor(self.block.x + 0.5 * self.block.width)
  local y2 = math.floor(self.block.y + 0.5 * self.block.height)

  for y = y1 + 1, y2 - 1 do
    self:collideTile(x1, y)
    self:collideTile(x2, y)
  end

  for x = x1 + 1, x2 - 1 do
    self:collideTile(x, y1)
    self:collideTile(x, y2)
  end

  self:collideTile(x1, y1)
  self:collideTile(x2, y1)

  self:collideTile(x1, y2)
  self:collideTile(x2, y2)
end

function Player:collideTile(x, y)
  local terrain = self.game.entitiesByName.terrain
  local tile = terrain:getTile(x, y)

  if tile then
    local direction = self.block:collideBox(x + 0.5, y + 0.5, 1, 1, 0, 0)

    if direction and self.digFlags[direction] then
      if tile == "stone" then
        terrain:setTile(x, y, "rubble")
      elseif tile == "rubble" then
        terrain:setTile(x, y, nil)
      end

      self.digFlags[direction] = false
    end
  end
end

function Player:draw()
  -- love.graphics.rectangle("line",
  --   self.block.x - 0.5 * self.block.width, self.block.y - 0.5 * self.block.height,
  --   self.block.width, self.block.height)

  local image = self.game.images.skins.ettin.stand
  local width, height = image:getDimensions()

  love.graphics.draw(self.game.images.skins.ettin.stand,
    self.block.x, self.block.y,
    0,
    self.direction * self.block.width / width, self.block.height / height,
    0.5 * width, 0.5 * height)
end

return Player
