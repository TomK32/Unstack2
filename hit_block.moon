require 'field'

export class HintBlock extends Field
  colors: {
    graphics.newGradient({200,200,200,255}, {155, 155, 155, 255}),
  }

  new: (shape, group, field) =>
    @group = group
    @shape = shape
    @field = field
    @createRects()
    return @

  createRect: (x, y, block) =>
    @shape[y][x] = display.newRect(unpack(Field.blockToRect(x,y)))
    @shape[y][x]\setFillColor(@colors[1])
    @shape[y][x].blendMode = 'add'
    transition.from(@shape[y][x], {
      time: 3000,
      alpha: 0,
      transition: easing.outExpo
    })
    @group\insert(@shape[y][x])

