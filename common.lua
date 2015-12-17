local common = {}

function common.round(x)
  return math.floor(x + 0.5)
end

function common.sign(x)
  return (x < 0) and -1 or 1
end

function common.clamp(x, x1, x2)
  return math.min(math.max(x, x1), x2)
end

function common.mix(x1, x2, t)
  return (1 - t) * x1 + t * x2
end

function common.smoothstep(x1, x2, x)
  local t = common.clamp((x - x1) / (x2 - x1), 0, 1)   
  return 3 * t ^ 2 - 2 * t ^ 3
end

function common.toByteFromFloat(x)
  return common.clamp(math.floor(x * 256), 0, 255)
end

return common
