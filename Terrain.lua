local Terrain = {}
Terrain.__index = Terrain

function Terrain.new(args)
  local terrain = {
    game = args.game,
    tiles = {},
  }

  terrain.game.drawHandlers.terrain[terrain] = Terrain.draw
  terrain.game.entitiesByName.terrain = terrain

  return setmetatable(terrain, Terrain)
end

function Terrain:destroy()
  self.game.entitiesByName.terrain = nil
  self.game.drawHandlers.terrain[self] = nil
end

function Terrain:getTile(x, y)
  return self.tiles[y] and self.tiles[y][x]
end

function Terrain:setTile(x, y, tile)
  if not self.tiles[y] then
    self.tiles[y] = {}
  end

  self.tiles[y][x] = tile
end

function Terrain:draw()
  for y, column in pairs(self.tiles) do
    for x, tile in pairs(column) do
      if tile then
        -- love.graphics.rectangle("line", x, y, 1, 1)
        local image = self.game.images.tiles[tile]
        local width, height = image:getDimensions()
        love.graphics.draw(image, x, y, 0, 1 / width, 1 / height)
      end
    end
  end
end

return Terrain
