

storyboard = require('storyboard')
scene = storyboard.newScene('Intro')
widget = require "widget"

local title

gotoMainMenu = () ->
  storyboard.purgeScene()
  storyboard.gotoScene("scenes.menu", "fade", 50)
  return true

scene.createScene = (event) =>
  background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  background\setFillColor(0,0,0,255)
  center = display.contentWidth / 2
  y = display.contentWidth / 4
  a = display.newText('ananasblau games', 0, y, native.systemFontBold, 22)
  a\setTextColor(30,150,30,255)
  a.x = center
  b = display.newText('present', 0, y + 30, native.systemFontBold, 12)
  b.x = center
  title = display.newText('Unstack 2', 0, y + 50, native.systemFontBold, 22)
  transition.from(title, {time: 1000, alpha: 0})
  title\setTextColor(255,255,100)
  title.x = center

  timer.performWithDelay(1000, gotoMainMenu)
  @view\insert(background)
  @view\insert(a)
  @view\insert(b)
  @view\insert(title)
  @view

scene\addEventListener( "createScene", scene )
Runtime\addEventListener("touch", gotoMainMenu)
Runtime\addEventListener("tap", gotoMainMenu)

return scene
-- storyboard.gotoScene("scenes.field")
