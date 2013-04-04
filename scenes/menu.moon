--  Unstack2 Menu
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.
-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

storyboard = require( "storyboard" )
scene = storyboard.newScene('Menu')
widget = require "widget"


-- Called when the scene's view does not exist:
scene.createScene = (event) =>

  -- display a background image
  background = display.newImageRect( "images/menu_background.png", display.contentWidth, display.contentHeight )
  background\setReferencePoint( display.TopLeftReferencePoint )
  background.x, background.y = 0, 0

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

  @view\insert(background)
  @view\insert(play_button)

scene.enterScene = (event) =>

scene.exitScene = (event) =>

scene.destroyScene = (event) =>
  if play_button then
    play_button\removeSelf() -- widgets must be manually removed
    play_button = nil

scene\addEventListener( "createScene", scene )
scene\addEventListener( "enterScene", scene )
scene\addEventListener( "exitScene", scene )
scene\addEventListener( "destroyScene", scene )

return scene

