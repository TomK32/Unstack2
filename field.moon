
export class Block
  colors: {
    {200,0,0,255},
    {0,200,0,255},
    {0,0,200,255}
  }

  standardBlocks: {
    {{1,1,1}, {nil,1,nil}}, -- T
    {{1,1,1}, {1,nil,nil}}, -- L
    {{1,1,1}, {nil,nil,1}}, -- inverse L
    {{nil, 1,1}, {1, 1, nil}}, -- z
    {{1,1, nil}, {nil, 1, 1}}, -- inverse z
    {{1,1,1, 1}}, -- long john
    {{1,1}, {1,1}}, -- massiveblock
    {{1,1,1}, {nil,1,nil}}, -- make the T more often than others
  }

  new: (shape) =>
    @shape = shape
    return @

  get: (x, y) =>
    if not @shape[y] or not @shape[y][x]
      return nil
    return @shape[y][x]

  set: (x, y, block) =>
    if not @shape[y]
      @shape[y] = {}
    @shape[y][x] = block

  blockToRect: (x,y) ->
   return {
     (x - 1) * game.block_size + 1,
     (y - 1) * game.block_size + 1,
     game.block_size - 2,
     game.block_size - 2}

  random: ->
    return Block(Block.standardBlocks[math.ceil(math.random() * #Block.standardBlocks)])

  rotations: ->
    if @rotatedShapes
      return @rotatedShapes
    else
      @rotatedShapes = { @, @\rotate() }
      @rotatedShapes[3] = @rotatedShapes[2]\rotate()
      @rotatedShapes[4] = @rotatedShapes[3]\rotate()

  -- returns a rotated version
  rotate: =>
    new_shape = {}
    for y=1, #@shape
      for x=1, #@shape[y]
        if not new_shape[x]
          new_shape[x] = {}
        new_shape[x][y] = @shape[y][x]
    return new_shape

  normalize: =>
    -- find area of interest
    min_x, min_y = nil, nil
    max_x, max_y = nil, nil
    for x, row in @shape
      for y, block in row
        print(x,y)
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
    for y=1, max_y - min_y
      for x=1, max_x - min_x
        new_shape[y][x] = @shape[min_y + y - 1][max_y + y - 1]
    return new_shape

  isLike: (other_block) =>
    normalized_shape = @\normalize()
    for i, rotated_shape in ipairs(other_shape\rotations())
      for y=1, #normalized_shape
        for x=1, #normalized_shape[y]
          if normalized_shape[y][x] and rotated_shape[y] and rotated_shape[y][x]
            return true
    return false


export class Field extends Block
  random: (group, level, height, width) ->
    empty_tiles = math.min(math.max(level - 1, math.floor(level/(height + width))), (width + height) / 2)
    shape = {}
    for y=1, width do
      shape[y] = {}
      for x=1, height do
        -- TODO: Use simplex noise
        if empty_tiles > 0 and math.random() < 1/math.sqrt(x+x*y+level+empty_tiles+1)
          empty_tiles -= 1
        else
          color = Field.colors[math.ceil(#Field.colors * math.random())]
          shape[y][x] = display.newRect(unpack(Field.blockToRect(x,y)))
          group\insert(shape[y][x])
          shape[y][x]\setFillColor(unpack(color))
          transition.from(shape[y][x], {time: 2000 / (x+2), alpha: 0, y: 0, x: 0})

    return Field(shape)

  @gestureShape: (event) ->
    if event.phase == 'began'
      game.gestureShapePoints = {} -- takes {x, y} pixel coords
      game.gestureBlock = Field({}) -- the block we draw
    table.insert(game.gestureShapePoints, {event.x, event.y})

    block_x = math.ceil(event.x / game.block_size)
    block_y = math.ceil(event.y / game.block_size)
    block = game.field\get(block_x, block_y)
    if not block or game.gestureBlock\get(block_x, block_y)
      -- nothing to do
      return false

    -- add to the shape we draw
    -- NOTE: this shape fits into the Field, for comparing with the
    --       wanted block it needs to be normalized first
    game.gestureBlock\set(block_x, block_y, block)

    if  event.phase == 'ended'
      if game.targetBlock\isLike(game.gestureBlock) then
        game.field\substract(match)

