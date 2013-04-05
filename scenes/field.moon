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


createTarget = () ->
  -- the block we need to mark
  game.targetBlock = Field(Block.random().shape, game.target_group)


gestureShape = (event) ->
  if event.phase == 'began'
    game.gestureShapePoints = {} -- takes {x, y} pixel coords
    game.gestureBlock = Block({}) -- the block we draw
  --table.insert(game.gestureShapePoints, {event.x, event.y})
  x = event.x - game.field.group.x
  y = event.y - game.field.group.y
  block_x = math.ceil(x / game.block_size)
  block_y = math.ceil(y / game.block_size)
  block = game.field\get(block_x, block_y)
  if not block
    game.gestureBlock = Block({})
    return true
  elseif game.gestureBlock\get(block_x, block_y)
    -- nothing to do
    return true
  game.gestureBlock\set(block_x, block_y, 1)

  -- add to the shape we draw
  -- NOTE: this shape fits into the Field, for comparing with the
  --       wanted block it needs to be normalized first

  if game.gestureBlock\isLike(game.targetBlock) then
    game.field\substract(match)
    game.targetBlock\removeSelf()
    createTarget()
  return true




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

  -- setup playing field
  game.field = Field.random(group, game.level, width, height)
  group\addEventListener( "touch", gestureShape )

  game.field.target = target_group

  game.target_group = display.newGroup()
  game.target_group.y = 0
  createTarget()

  @view
--Runtime\addEventListener( "touch", gestureShape )
scene\addEventListener( "createScene", scene )
--Runtime\addEventListener( "enterFrame", game.field.draw)


return scene


