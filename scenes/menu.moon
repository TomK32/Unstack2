--  Unstack2 Menu
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.

scene = storyboard.newScene('Menu')
widget = require "widget"
require 'field'

doBackgroundBlocks = true
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
  scene.background_group = display.newGroup()
  doBackgroundBlocks = true
  backgroundBlocks(scene.background_group)

  @view\insert(scene.background_group)

  play_button = widget.newButton({
    label: "Play Now",
    labelColor: { default: {0}, over: {0} },
    top: display.contentHeight * 0.5,
    onRelease: ->
      storyboard.gotoScene("scenes.field", "fade", 50)
      analytics.newEvent("design", {event_id: "menu:play"})
      return true
  })

  play_button\setReferencePoint(display.CenterReferencePoint)
  play_button.x = display.contentWidth * 0.5

  games_button = widget.newButton({
    label: 'More games',
    top: play_button.y + play_button.height,
    onRelease: ->
      system.openURL( 'http://ananasblau.com/games?utm_source=unstack2&utm_medium=android&utm_term=main+menu&utm_campaign=games' )
  })
  games_button.x = play_button.x

  @view\insert(play_button)

scene.exitScene = (event) ->
  doBackgroundBlocks = false

scene\addEventListener( "createScene", scene )
scene\addEventListener( "enterScene", scene )
scene\addEventListener( "exitScene", scene )

return scene

