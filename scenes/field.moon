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
  group\addEventListener( "touch", Field.gestureShape )
  group.touch = Field.gestureShape

  -- first block we need to mark
  game.targetBlock = Block.random()
  @view

--Runtime\addEventListener( "touch", gestureShape )
scene\addEventListener( "createScene", scene )
--Runtime\addEventListener( "enterFrame", game.field.draw)


return scene


