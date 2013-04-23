--  Unstack2 Field
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.

scene = storyboard.newScene('HowTo')

gotoMainMenu = (event) ->
  storyboard.gotoScene("scenes.menu", "fade", 50)

  return true


scene.printLine = (text, x, y, width, font_size) =>
  t = display.newText(text, x, y, width, 0, native.systemFontBold, font_size)
  t\setReferencePoint(display.TopRightReferencePoint)
  @view\insert t
  return y + t.height * 1.2


scene.createScene = (event) =>
  background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  background\setFillColor(0,0,0,255)
  @view\insert(background)

  x = game.block_size
  y = math.ceil(display.contentHeight / 40)
  width = display.contentWidth - game.block_size * 2
  line_height = math.floor(display.contentHeight / 16)
  font_size = math.floor(math.max(10, line_height / 2))

  y = @\printLine('HowTo', x * 1.4, y, width, font_size * 1.6)
  y = @\printLine('The yellow shape is what you must draw on the large field.', x, y, width, font_size)
  y = @\printLine('In the middle you see your score and the time remaining', x, y, width, font_size)

  howto_header = display.newImage(@view, 'images/howto-header.png', 0, y)
  y += howto_header.height

  y = @\printLine('Start with any block, swipe the shape and lift your finger.', x, y, width, font_size)

  howto_swipe = display.newImage(@view, 'images/howto-swipe.png', 0, y)
  howto_swipe.height = 0
  y += howto_swipe.height + game.block_size / 2

  y = @\printLine("Colours or orientation don't matter but give you bonuses.", x, y, width, font_size)

  @view\addEventListener("touch", gotoMainMenu)
  @view\addEventListener("tap", gotoMainMenu)
  @view

scene.exitScene = (event) =>
  storyboard.purgeScene()


scene\addEventListener( "createScene", scene )
scene\addEventListener( "exitScene", scene )

return scene

