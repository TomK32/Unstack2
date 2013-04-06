--  Unstack2 Menu
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.
-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

scene = storyboard.newScene('Menu')
widget = require "widget"

backgroundBlocks = (group) ->
  w = math.floor(display.contentWidth / game.block_size)
  h = math.floor(display.contentHeight / game.block_size)
  if group.field
    group.field\removeSelf()
  group.field = Field.random(group, 50, w, h)
  timer.performWithDelay 2000, -> backgroundBlocks(group)

-- Called when the scene's view does not exist:
scene.createScene = (event) =>

  -- display a background image
  background = display.newImageRect( "images/menu_background.png", display.contentWidth, display.contentHeight )
  background\setReferencePoint( display.TopLeftReferencePoint )
  background.x, background.y = 0, 0
  @view\insert(background)

  background_group = display.newGroup()
  @view\insert(background_group)
  backgroundBlocks(background_group)

  play_button = widget.newButton({
    label: "Play Now",
    labelColor: { default: {0}, over: {0} },
    width: 154, height: 40,
    onRelease: ->
      storyboard.gotoScene("scenes.field", "fade", 50)
      return true
  })

  play_button\setReferencePoint(display.CenterReferencePoint)
  play_button.x = display.contentWidth * 0.5
  play_button.y = display.contentHeight - 125

  @view\insert(play_button)


scene\addEventListener( "createScene", scene )

return scene

