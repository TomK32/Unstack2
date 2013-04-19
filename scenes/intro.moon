

storyboard = require('storyboard')
scene = storyboard.newScene('Intro')
widget = require "widget"

local title

gotoMainMenu = (event) ->
  if string.find(storyboard.getCurrentSceneName(), 'intro')
    storyboard.gotoScene("scenes.menu", "fade", 50)

  return true

scene.createScene = (event) =>
  background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  background\setFillColor(0,0,0,255)
  center = display.contentWidth / 2
  y = display.contentHeight / 4
  a = display.newText('ananasblau games', 0, y, native.systemFontBold, 22)
  a\setTextColor(30,150,30,255)
  a.x = center
  b = display.newText('present', 0, y + 30, native.systemFontBold, 12)
  b.x = center
  title = display.newText('Unstack 2', 0, y + 50, native.systemFontBold, 32)
  transition.from(title, {time: 1000, alpha: 0})
  title\setTextColor(255,255,100)
  title.x = center

  c = display.newText('Thanks to: devlol, #1gam, coronalabs', 0, y + 150, native.systemFontBold, 16)
  c.x = center

  d = display.newText('SFX by: ananasblau', 0, y + 170, native.systemFontBold, 16)
  d.x = center

  timer.performWithDelay(2000, gotoMainMenu)
  @view\insert(background)
  @view\insert(a)
  @view\insert(b)
  @view\insert(c)
  @view\insert(d)
  @view\insert(title)
  @view\addEventListener("touch", gotoMainMenu)
  @view\addEventListener("tap", gotoMainMenu)
  @view

scene.exitScene = (event) =>
  if event and (event.name == 'tap' or event.name == 'touch')
    analytics.newEvent("design", {event_id: "intro:skipped", value: event.time})
  storyboard.purgeScene()

scene\addEventListener( "exitScene", scene )
scene\addEventListener( "createScene", scene )

return scene
-- storyboard.gotoScene("scenes.field")
