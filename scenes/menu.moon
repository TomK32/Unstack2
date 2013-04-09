--  Unstack2 Menu
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.

scene = storyboard.newScene('Menu')
widget = require "widget"

doBackgroundBlocks = true
background_group = display.newGroup()
last_background_blocks = 0

backgroundBlocks = (group) ->
  if not doBackgroundBlocks or (last_background_blocks and last_background_blocks + 2 > os.time())
    return false
  last_background_blocks = os.time()
  w = math.floor(display.contentWidth / game.block_size)
  h = math.floor(display.contentHeight / game.block_size)
  if group.field
    group.field\removeSelf()
  group.field = Field.random(group, 50, w, h)
  timer.performWithDelay 3000, -> backgroundBlocks(group)

-- Called when the scene's view does not exist:

scene.enterScene = (event) =>
  -- display a background image
  background = display.newImageRect( "images/menu_background.png", display.contentWidth, display.contentHeight )
  background\setReferencePoint( display.TopLeftReferencePoint )
  background.x, background.y = 0, 0
  @view\insert(background)

  @view\insert(background_group)

  play_button = widget.newButton({
    label: "Play Now",
    labelColor: { default: {0}, over: {0} },
    width: game.block_size * 6, height: game.block_size * 2,
    onRelease: ->
      storyboard.gotoScene("scenes.field", "fade", 50)
      analytics.newEvent("design", {event_id: "menu:play"})
      return true
  })

  play_button\setReferencePoint(display.CenterReferencePoint)
  play_button.x = display.contentWidth * 0.5
  play_button.y = display.contentHeight - 125

  @view\insert(play_button)

scene.createScene = (event) =>
  doBackgroundBlocks = true
  backgroundBlocks(background_group)

scene.exitScene = (event) ->
  doBackgroundBlocks = false

scene\addEventListener( "createScene", scene )
scene\addEventListener( "enterScene", scene )
scene\addEventListener( "exitScene", scene )

return scene

