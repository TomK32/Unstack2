--  Unstack2 Field
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.
-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

storyboard = require( "storyboard" )
scene = storyboard.newScene('Field')
widget = require "widget"

class Field extends Block
  colors: {
    {200,0,0,255},
    {0,200,0,255},
    {0,0,200,255}
  }

  new: (shape) =>
    @shape = shape
    return @

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
          shape[y][x] = display.newRect(unpack(Field.blockRect(x,y)))
          group\insert(shape[y][x])
          shape[y][x]\setFillColor(unpack(color))
          transition.from(shape[y][x], {time: 2000 / (x+4), alpha: 0, y: 0, x: 0})

    return Field(blocks)

  blockRect: (x,y) ->
   return {
     (x - 1) * game.block_size + 1,
     (y - 1) * game.block_size + 1,
     game.block_size - 2,
     game.block_size - 2}


-- Called when the scene's view does not exist:
scene.createScene = (event) =>
  -- view size will take full width but leave a few block on the top
  group = display.newGroup()
  group.y = 3 * game.block_size
  width = math.floor(display.contentWidth / game.block_size)
  height = math.floor(display.contentHeight / game.block_size) - 3
  background = display.newRect(0, 0, width * game.block_size, height * game.block_size)
  background\setFillColor(30,30,30,255)
  group\insert(background)
  game.field = Field.random(group, game.level, width, height)
  @view


scene\addEventListener( "createScene", scene )
--Runtime:addEventListener( "enterFrame", game.field.draw)


return scene


