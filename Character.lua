local common = require "common"
local Box = require "Box"

local Character = {}
Character.__index = Character

function Character.new(args)
  local character = {
    destroyed = false,
    game = args.game,
    state = "stand",
    direction = args.direction or 1,

    inputs = {
      left = false, right = false,
    },

    oldInputs = {
      left = false, right = false,
    },

    standAcceleration = args.standAcceleration or 20,
    fallAcceleration = args.fallAcceleration or 20,
    stompAcceleration = args.stompAcceleration or 40,
    crouchAcceleration = args.crouchAcceleration or 40,

    walkVelocity = args.walkVelocity or 4,
    walkAcceleration = args.walkAcceleration or 20,

    pushVelocity = args.pushVelocity or 4,
    pushAcceleration = args.pushAcceleration or 20,

    digVelocity = args.digVelocity or 4,
    digAcceleration = args.digAcceleration or 20,

    highJumpVelocity = args.highJumpVelocity or 11.625,
    lowJumpVelocity = args.lowJumpVelocity or 5.8125,

    glideVelocity = args.glideVelocity or 2,
    glideAcceleration = args.glideAcceleration or 10,

    wallSlideVelocity = args.wallSlideVelocity or 4,
    wallSlideAcceleration = args.wallSlideAcceleration or 20,

    climbVelocity = args.wallSlideVelocity or 2,
    climbAcceleration = args.wallSlideAcceleration or 40,
    climbDigAcceleration = args.climbDigAcceleration or 20,

    wallJumpVelocity = args.wallJumpVelocity or 4,

    digTime = args.digTime or 0.5,

    tileCollisions = {
      left = {}, right = {},
      up = {}, down = {},
    },

    currentDigTime = 0,
  }

  character.box = Box.new({
    x = args.x, y = args.y,
    width = args.width, height = args.height,
    velocityX = args.velocityX, velocityY = args.velocityY,
  })

  character.game.updateHandlers.character[character] = Character.update
  character.game.updateHandlers.camera[character] = Character.updateCamera
  character.game.drawHandlers.character[character] = Character.draw

  return setmetatable(character, Character)
end

function Character:destroy()
  self.game.drawPasses.character[self] = nil
  self.game.updateHandlers.camera[self] = nil
  self.game.updateHandlers.character[self] = nil
  self.destroyed = true
end

function Character:update(dt)
  self:updateInput()
  self:transition()
  self:control(dt)
  self:collide()
end

function Character:updateInput()
  self.oldInputs.left = self.inputs.left
  self.oldInputs.right = self.inputs.right

  self.inputs.left = love.keyboard.isDown("left")
  self.inputs.right = love.keyboard.isDown("right")
end

function Character:updateCamera(dt)
  local camera = self.game.entitiesByName.camera
  local maxCameraDistanceX, maxCameraDistanceY = 1, 1
  camera.x = common.clamp(camera.x, self.box.x - maxCameraDistanceX, self.box.x + maxCameraDistanceX)
  camera.y = common.clamp(camera.y, self.box.y - maxCameraDistanceY, self.box.y + maxCameraDistanceY)

  local width, height = love.window.getDimensions()
  local scale = 0.5 * camera.scale * height
  local viewportWidth, viewportHeight = width / scale, height / scale

  local terrain = self.game.entitiesByName.terrain

  if viewportWidth < terrain.tileWidth * terrain.width then
    camera.x = common.clamp(camera.x, 0.5 * viewportWidth + 0.5 * terrain.tileWidth,
      terrain.tileWidth * (terrain.width + 0.5) - 0.5 * viewportWidth)
  else
    camera.x = terrain.tileWidth * (0.5 * terrain.width + 0.5)
  end

  if viewportHeight < terrain.tileHeight * terrain.height then
    camera.y = common.clamp(camera.y,  0.5 * viewportHeight + 0.5 * terrain.tileHeight,
      terrain.tileHeight * (terrain.height + 0.5) - 0.5 * viewportHeight)
  else
    camera.y = terrain.tileHeight * (0.5 * terrain.height + 0.5)
  end
end

function Character:transition()
  if self.state == "climb" then
    self:transitionClimb()
  elseif self.state == "climbDig" then
    self:transitionClimbDig()
  elseif self.state == "dig" then
    self:transitionDig()
  elseif self.state == "crouch" then
    self:transitionCrouch()
  elseif self.state == "fall" then
    self:transitionFall()
  elseif self.state == "jump" then
    self:transitionJump()
  elseif self.state == "push" then
    self:transitionPush()
  elseif self.state == "stand" then
    self:transitionStand()
  elseif self.state == "stomp" then
    self:transitionStomp()
  elseif self.state == "walk" then
    self:transitionWalk()
  elseif self.state == "wallSlide" then
    self:transitionWallSlide()
  end
end

function Character:transitionClimb()
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)
  local collisionX = (next(self.tileCollisions.right) and 1 or 0) - (next(self.tileCollisions.left) and 1 or 0)

  if collisionX == 0 or inputX == -collisionX then
    self.state = "fall"
    return
  end

  if not (self.inputs.left or self.inputs.right) then
    self.state = "wallSlide"
    return
  end

  if self.inputs.left and self.inputs.right then
    self.state = "climbDig"
    return
  end
end

function Character:transitionClimbDig()
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)
  local collisionX = (next(self.tileCollisions.right) and 1 or 0) - (next(self.tileCollisions.left) and 1 or 0)

  if collisionX == 0 or inputX == -collisionX then
    self.state = "fall"
    return
  end

  if not (self.inputs.left or self.inputs.right) then
    self.state = "wallSlide"
    return
  end

  if inputX == collisionX then
    self:dig((self.direction == 1) and "right" or "left")
    self.state = "climb"
    return
  end
end

function Character:transitionCrouch()
  if not next(self.tileCollisions.down) then
    self.state = "fall"
    return
  end

  if not (self.inputs.left and self.inputs.right) then
    self.state = "stand"
  end
end

function Character:transitionDig()
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)
  local collisionX = (next(self.tileCollisions.right) and 1 or 0) - (next(self.tileCollisions.left) and 1 or 0)

  if not next(self.tileCollisions.down) then
    self.state = "fall"
    return
  end

  if inputX == collisionX then
    self:dig((collisionX == -1) and "left" or "right")
    self.state = "climb"
    return
  end

  if not (self.inputs.right and self.inputs.left) then
    self.state = "stand"
    return
  end
end

function Character:transitionFall()
  if next(self.tileCollisions.down) then
    self.state = "stand"
    return
  end

  if next(self.tileCollisions.left) or next(self.tileCollisions.right) then
    self.state = "wallSlide"
    return
  end

  if (self.inputs.left and self.inputs.right) and not (self.oldInputs.left and self.oldInputs.right) then
    self.state = "stomp"
  end
end

function Character:transitionJump()
  if next(self.tileCollisions.down) then
    self.state = "stand"
    return
  end

  if next(self.tileCollisions.up) then
    self.state = "fall"
    self:dig("up")
    return
  end

  if not (self.inputs.right and self.inputs.left) then
    self.state = "fall"
    self.box.velocityY = math.max(self.box.velocityY, -self.lowJumpVelocity)
    return
  end
end

function Character:transitionPush()
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)
  local collisionX = (next(self.tileCollisions.right) and 1 or 0) - (next(self.tileCollisions.left) and 1 or 0)

  if not next(self.tileCollisions.down) then
    self.state = "fall"
    return
  end

  if self.inputs.right and self.inputs.left then
    self.state = "dig"
    return
  end

  if inputX ~= collisionX then
    self.state = "stand"
    return
  end
end

function Character:transitionStand()
  if not next(self.tileCollisions.down) then
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

function Character:transitionStomp()
  if next(self.tileCollisions.down) then
    self:dig("down")
    self.state = "crouch"
    return
  end

  if not (self.inputs.left and self.inputs.right) then
    self.state = "fall"
    return
  end
end

function Character:transitionWalk()
  if not next(self.tileCollisions.down) then
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

  if next(self.tileCollisions.left) or next(self.tileCollisions.right) then
    self.state = "climb"
    return
  end
end

function Character:transitionWallSlide()
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)
  local collisionX = (next(self.tileCollisions.right) and 1 or 0) - (next(self.tileCollisions.left) and 1 or 0)

  if collisionX ~= 0 and inputX == collisionX then
    self.state = "climb"
    return
  end

  if next(self.tileCollisions.down) then
    self.state = "stand"
    return
  end

  if collisionX == 0 or inputX == -collisionX then
    self.state = "fall"
    return
  end
end

function Character:control(dt)
  if self.state == "climb" then
    self:controlClimb(dt)
  elseif self.state == "climbDig" then
    self:controlClimbDig(dt)
  elseif self.state == "crouch" then
    self:controlCrouch(dt)
  elseif self.state == "dig" then
    self:controlDig(dt)
  elseif self.state == "fall" then
    self:controlFall(dt)
  elseif self.state == "jump" then
    self:controlJump(dt)
  elseif self.state == "push" then
    self:controlPush(dt)
  elseif self.state == "stand" then
    self:controlStand(dt)
  elseif self.state == "stomp" then
    self:controlStomp(dt)
  elseif self.state == "walk" then
    self:controlWalk(dt)
  elseif self.state == "wallSlide" then
    self:controlWallSlide(dt)
  end
end

function Character:controlClimb(dt)
  local velocityErrorY = -self.climbVelocity - self.box.velocityY

  local collisionX = (next(self.tileCollisions.right) and 1 or 0) - (next(self.tileCollisions.left) and 1 or 0)

  self.box.velocityX = collisionX * self.glideVelocity

  self.box.velocityY = (self.box.velocityY + common.sign(velocityErrorY) *
    math.min(math.abs(velocityErrorY), self.climbAcceleration * dt))

  self:updatePosition(dt)
end

function Character:controlClimbDig(dt)
  local velocityErrorY = -self.box.velocityY

  local collisionX = (next(self.tileCollisions.right) and 1 or 0) - (next(self.tileCollisions.left) and 1 or 0)

  self.box.velocityX = collisionX * self.glideVelocity

  self.box.velocityY = (self.box.velocityY + common.sign(velocityErrorY) *
    math.min(math.abs(velocityErrorY), self.climbDigAcceleration * dt))

  self:updatePosition(dt)
end

function Character:controlCrouch(dt)
  self:fall(dt)

  local velocityError = -self.box.velocityX

  self.box.velocityX = (self.box.velocityX + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.crouchAcceleration * dt))

  self:updatePosition(dt)
end

function Character:controlDig(dt)
  self:fall(dt)

  local targetVelocity = self.direction * self.digVelocity
  local velocityError = targetVelocity - self.box.velocityX

  self.box.velocityX = (self.box.velocityX + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.digAcceleration * dt))

  self:updatePosition(dt)
end

function Character:controlFall(dt)
  self:turn()
  self:fall(dt)
  self:glide(dt)
  self:updatePosition(dt)
end

function Character:controlJump(dt)
  self:turn()
  self:fall(dt)
  self:glide(dt)
  self:updatePosition(dt)
end

function Character:controlPush(dt)
  self:fall(dt)

  local targetVelocity = self.direction * self.pushVelocity
  local velocityError = targetVelocity - self.box.velocityX

  self.box.velocityX = (self.box.velocityX + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.pushAcceleration * dt))

  self:updatePosition(dt)
end

function Character:controlStand(dt)
  self:fall(dt)

  local velocityError = -self.box.velocityX

  self.box.velocityX = (self.box.velocityX + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.standAcceleration * dt))

  self:updatePosition(dt)
end

function Character:controlStomp(dt)
  self.box.velocityY = self.box.velocityY + self.stompAcceleration * dt
  self:updatePosition(dt)
end

function Character:controlWalk(dt)
  self:turn()
  self:fall(dt)

  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)
  local targetVelocity = inputX * self.walkVelocity
  local velocityError = targetVelocity - self.box.velocityX

  self.box.velocityX = (self.box.velocityX + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.walkAcceleration * dt))

  self:updatePosition(dt)
end

function Character:controlWallSlide(dt)
  local collisionX = (next(self.tileCollisions.right) and 1 or 0) - (next(self.tileCollisions.left) and 1 or 0)
  local velocityError = self.wallSlideVelocity - self.box.velocityY

  self.box.velocityX = collisionX * self.glideVelocity
  self.box.velocityY = (self.box.velocityY + common.sign(velocityError) *
    math.min(math.abs(velocityError), self.wallSlideAcceleration * dt))

  self:updatePosition(dt)
end

function Character:turn()
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)

  if inputX ~= 0 then
    self.direction = inputX
  end
end

function Character:fall(dt)
  self.box.velocityY = self.box.velocityY + self.fallAcceleration * dt
end

function Character:glide(dt)
  local inputX = (self.inputs.right and 1 or 0) - (self.inputs.left and 1 or 0)

  if inputX ~= 0 then
    local targetVelocity = inputX * math.max(self.glideVelocity, inputX * self.box.velocityX)
    local velocityError = targetVelocity - self.box.velocityX

    self.box.velocityX = (self.box.velocityX + common.sign(velocityError) *
      math.min(math.abs(velocityError), self.glideAcceleration * dt))
  end
end

function Character:jump()
  self.box.velocityY = -self.highJumpVelocity
end

function Character:updatePosition(dt)
  self.box.x = self.box.x + self.box.velocityX * dt
  self.box.y = self.box.y + self.box.velocityY * dt
end

function Character:collide()
  local terrain = self.game.entitiesByName.terrain

  for direction, _ in pairs(self.tileCollisions) do
    self.tileCollisions[direction] = {}
  end

  local x1 = common.round((self.box.x - 0.5 * self.box.width) / terrain.tileWidth)
  local y1 = common.round((self.box.y - 0.5 * self.box.height) / terrain.tileHeight)

  local x2 = common.round((self.box.x + 0.5 * self.box.width) / terrain.tileWidth)
  local y2 = common.round((self.box.y + 0.5 * self.box.height) / terrain.tileHeight)

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

function Character:collideTile(x, y)
  local terrain = self.game.entitiesByName.terrain
  local tile = terrain:getTile(x, y)

  if tile then
    local direction = self.box:collideBox(terrain.tileWidth * x, terrain.tileHeight * y,
      terrain.tileWidth, terrain.tileHeight, 0, 0)

    if direction then
      table.insert(self.tileCollisions[direction], {x, y})
    end
  end
end

function Character:dig(direction)
  local epsilon = 1 / 256

  if direction == "left" then
    self:dig2(self.box.x - epsilon, self.box.y, self.box.width, self.box.height - epsilon)
  elseif direction == "right" then
    self:dig2(self.box.x + epsilon, self.box.y, self.box.width, self.box.height - epsilon)
  elseif direction == "up" then
    self:dig2(self.box.x, self.box.y - epsilon, self.box.width - epsilon, self.box.height)
  elseif direction == "down" then
    self:dig2(self.box.x, self.box.y + epsilon, self.box.width - epsilon, self.box.height)
  end
end

function Character:dig2(x, y, width, height)
  local terrain = self.game.entitiesByName.terrain

  local x1 = common.round((x - 0.5 * width) / terrain.tileWidth)
  local y1 = common.round((y - 0.5 * height) / terrain.tileHeight)

  local x2 = common.round((x + 0.5 * width) / terrain.tileWidth)
  local y2 = common.round((y + 0.5 * height) / terrain.tileHeight)

  for y = y1, y2 do
    for x = x1, x2 do
      self:digTile(x, y)
    end
  end
end

function Character:digTile(x, y)
  local terrain = self.game.entitiesByName.terrain
  local tile = terrain:getTile(x, y)

  if tile == "stone" then
  --   terrain:setTile(x, y, "rubble")
  -- elseif tile == "rubble" then
    terrain:setTile(x, y, nil)
  end
end

function Character:draw()
  -- love.graphics.rectangle("line",
  --   self.box.x - 0.5 * self.box.width, self.box.y - 0.5 * self.box.height,
  --   self.box.width, self.box.height)

  local image = self.game.images.skins.ettin.stand
  local width, height = image:getDimensions()

  love.graphics.draw(self.game.images.skins.ettin.stand,
    self.box.x, self.box.y,
    0,
    self.direction * (1 / 32), (1 / 32),
    0.5 * width, 0.5 * height)
end

return Character
