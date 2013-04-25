require 'block'

export class Field extends Block

  new: (shape, group, level, colors) =>
    @group = group
    @level = level
    @shape = shape
    @colors = colors
    @createRects()
    return @

  get: (x, y) =>
    b = Block.get(self, x, y)
    if not b or b.removed
      return nil
    return b

  blockToRect: (x,y, block_size) ->
    block_size = block_size or game.block_size
    return {
      (x - 1) * block_size + 1,
      (y - 1) * block_size + 1,
      block_size - 2,
      block_size - 2
    }

  removeSelf: =>
    for y, row in pairs(@shape)
      for x, block in pairs(row)
        if type(block) == 'table' and block.removeSelf
          block\removeSelf()

  createRects: =>
    for y, row in pairs(@shape)
      for x, block in pairs(row)
        if block
          @\createRect(x, y, block)

  createRect: (x, y, block) =>
    color_num = math.ceil(#@colors * math.random())
    color = @colors[color_num]
    @shape[y][x] = display.newRect(unpack(Field.blockToRect(x,y)))
    @shape[y][x]\setFillColor(color)
    @shape[y][x].blendMode = 'add'
    @shape[y][x].color_num = color_num
    trans_x = math.random() * x * 2 * game.block_size
    trans_y = math.random() * y * 2 * game.block_size
    transition.from(@shape[y][x], {
      time: 500, alpha: 0,
      width: game.block_size * 10,
      rotation: y - x,
      y: trans_y, x: trans_x})
    @group\insert(@shape[y][x])
    return @shape[y][x]

  random: (group, level, height, width) ->
    shape = {}
    for y=1, width do
      shape[y] = {}
      for x=1, height do
        shape[y][x] = 1

    return Field(shape, group, level)

  blocksLeft: () =>
    blocks_left = 0
    for y, row in pairs(@shape)
      for x, b in pairs(row)
        if b ~= nil and b ~= false and b.removed ~= true
          blocks_left += 1
    return blocks_left

  cleared: () =>
    return @blocksLeft() == 0

  substract: (block, callback) =>
    field = @
    for y, row in pairs(block.shape)
      for x, b in pairs(row)
        @substractBlock(x, y, callback)

  substractBlock: (x, y, callback) =>
    if @shape[y] and @shape[y][x]
      @shape[y][x].removed = true
      if callback
        callback(@, x, y)
      elseif @shape[y][x].removeSelf
        @shape[y][x]\removeSelf()

