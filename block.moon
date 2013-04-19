
export class Block
  colors: {
    graphics.newGradient({200,50,50}, {255, 150,50}),
    graphics.newGradient({50,200,50}, {150, 255,50}),
    graphics.newGradient({50,50,200}, {50, 150,255}),
  }

  standardBlocks: {
    {{1,1,1}, {1}}, -- L
    {{1,1,1}, {false,false,1}}, -- inverse L
    {{false, 1,1}, {1, 1, false}}, -- z
    {{1,1, false}, {false, 1, 1}}, -- inverse z
    {{1,1,1}}, -- long john
    {{1,1}}, -- little johnny
    {{1,1,1},{1,false,1}, {1,1,1}}, -- circle
    {{1,1}, {1,1}}, -- massive block
    {{1,1}, {false, 1}},
    {{1,1}, {1, false}}
    {{1,1}}, -- little johnny
  }

  new: (shape, colors) =>
    @shape = shape
    @colors = colors
    return @

  get: (x, y) =>
    if not @shape[y] or not @shape[y][x]
      return nil
    return @shape[y][x]

  set: (x, y, block) =>
    if not @shape
      @shape = {}
    if not @shape[y]
      @shape[y] = {}
    @shape[y][x] = block
    return block

  randomStandardShape: ->
    shape = Block.standardBlocks[math.ceil(math.random() * #Block.standardBlocks)]
    return Block(shape)\rotations()[math.ceil(math.random() * 4)]

  random: ->
    shape = {}
    for y, row in pairs(Block.randomStandardShape())
      shape[y] = {}
      for x, block in pairs(row)
        shape[y][x] = block
    return Block(shape)

  rotations: =>
    if @rotatedShapes
      return @rotatedShapes

    @rotatedShapes = { @shape }
    @rotatedShapes[2] = @.rotate(@rotatedShapes[1])
    @rotatedShapes[3] = @.rotate(@rotatedShapes[2])
    @rotatedShapes[4] = @.rotate(@rotatedShapes[3])
    return @rotatedShapes

  -- returns a rotated version
  rotate: (shape) ->
    rotated = {}
    w = 0
    h = 0
    for y, row in pairs(shape)
      if y > h
        h = y
      for x in pairs(row)
        if x > w
          w = x
    for y=1, h do
      for x=1, w do
        if not rotated[w - x + 1]
          rotated[w - x + 1] = {}
        if shape[y]
          rotated[w - x + 1][y] = shape[y][x]
    return rotated

  normalize: =>
    -- find area of interest
    min_x, min_y = nil, nil
    max_x, max_y = nil, nil
    for y, row in pairs(@shape)
      for x, block in pairs(row)
        if block
          if not min_x or x < min_x
            min_x = x
          if not min_y or y < min_y
            min_y = y
          if not max_x or x > max_x
            max_x = x
          if not max_y or y > max_y
            max_y = y

    new_shape = {}
    for y=1, max_y - min_y + 1
      new_shape[y] = {}
      if @shape[min_y + y - 1]
        for x=1, max_x - min_x + 1
          new_shape[y][x] = @shape[min_y + y - 1][min_x + x - 1] or false
    return new_shape

  matchShapes: (s1,s2) ->
    -- Use usual comparison first.
    if s1 == nil or s2 == nil
      return false
    for y, row in pairs(s1) do
      if not s2[y]
        return false
      for x, b in pairs(row) do
        if not (b and s2[y][x]) and not (not b and not s2[y][x])
          return false
    for y, row in pairs(s2) do
      if not s1[y]
        return false
      for x, b in pairs(row) do
        if not (b and s1[y][x]) and not (not b and not s1[y][x])
          return false
    return true


  isLike: (other_block) =>
    normalized_shape = @\normalize()
    if next(normalized_shape) == nil -- We haven't draw anything yet
      return false
    for i, rotated_shape in ipairs(other_block\rotations())
      if @.matchShapes(normalized_shape, rotated_shape)
        return true
    return false

  height: =>
    h = 0
    for y, row in pairs(@shape)
      if y and y > h
        h = y
    return h

  width: =>
    w = 0
    for y, row in pairs(@shape)
      for x, b in pairs(row)
        if x and x > w
          w = x
    return w

  toString: () =>
    str = "\n" .. @\height() .. 'x' .. @\width() .. "\n"
    for y=1, @\height()
      for x=1, @\width()
        if @shape[y] and @shape[y][x]
          str = str .. '1'
        else
          str = str .. '.'
      str = str .. "\n"
    return str

  -- number of blocks in the shape
  weight: () =>
    counter = 0
    for y, row in pairs(@shape)
      for x, b in pairs(row)
        counter += 1
    return counter

  move: (offset_x, offset_y) =>
    new_shape = {}
    print(offset_y, offset_x)
    for y, row in pairs(@shape)
      new_shape[y + offset_y] = {}
      for x, tile in pairs(row)
        new_shape[y + offset_y][x + offset_x] = tile
    @shape = new_shape


