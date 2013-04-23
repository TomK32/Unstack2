--  Unstack2 Field
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.

scene = storyboard.newScene('HighScores')

gotoMainMenu = (event) ->
  storyboard.gotoScene("scenes.menu", "fade", 50)

  return true

scene.createScene = (event) =>
  background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  background\setFillColor(0,0,0,255)
  @view\insert(background)

  x = game.block_size
  y = math.ceil(display.contentHeight / 20)
  line_height = math.floor(display.contentHeight / 16)
  font_size = math.floor(math.max(10, line_height / 2))
  line = display.newText('Highscores', x * 1.2, y, native.systemFontBold, font_size * 1.6)
  line\setReferencePoint(display.TopRightReferencePoint)
  @view\insert line
  game.highscores\tidyHighscores()
  for i, score in ipairs(game.highscores.highscores)
    y += line_height * 1.2
    text = score.score .. ' (lvl ' .. score.level .. ') .. ' .. score.date
    line = display.newText(text, x, y, native.systemFontBold, font_size)
    @view\insert(line)
  @view\addEventListener("touch", gotoMainMenu)
  @view\addEventListener("tap", gotoMainMenu)
  @view

scene.exitScene = (event) =>
  storyboard.purgeScene()


scene\addEventListener( "createScene", scene )
scene\addEventListener( "exitScene", scene )

return scene
