local Terrain = {}
Terrain.__index = Terrain

function Terrain.new(args)
  local terrain = {
    game = args.game,
    width = args.width or 1, height = args.height or 1,
    tileWidth = args.tileWidth or 1, tileHeight = args.tileHeight or 1,
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
  return self.tiles[x] and self.tiles[x][y]
end

function Terrain:setTile(x, y, tile)
  if not self.tiles[x] then
    self.tiles[x] = {}
  end

  self.tiles[x][y] = tile
end

function Terrain:setTiles(x, y, width, height, tile)
  for i = x, x + width - 1 do
    for j = y, y + height - 1 do
      self:setTile(i, j, tile)
    end
  end
end

function Terrain:draw()
  for x, column in pairs(self.tiles) do
    for y, tile in pairs(column) do
      if tile then
        -- love.graphics.rectangle("line", x, y, 1, 1)
        local image = self.game.images.tiles[tile]
        local width, height = image:getDimensions()
        love.graphics.draw(image,
          self.tileWidth * (x - 0.5), self.tileWidth * (y - 0.5), 0,
          self.tileWidth / width, self.tileWidth / height)
      end
    end
  end
end

return Terrain
