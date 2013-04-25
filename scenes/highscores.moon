--  Unstack2 Field
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.

scene = storyboard.newScene('HighScores')

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

  width = display.contentHeight - 2 * game.block_size
  x = game.block_size
  y = math.ceil(display.contentHeight / 20)
  line_height = math.floor(display.contentHeight / 16)
  font_size = math.floor(math.max(10, line_height / 2))
  y = @\printLine('Highscores', x * 1.4, y, width, font_size * 1.6)

  game.highscores\tidyHighscores()

  if game.highscores.total_games
    y = @\printLine(game.highscores.total_games .. ' games', x, y, width, font_size)
  if game.highscores.total_score
    y = @\printLine(game.highscores.total_score .. ' total score', x, y, width, font_size)

  for i, score in ipairs(game.highscores.highscores)
    text = math.floor(score.score) .. ' (lvl ' .. score.level .. ') .. ' .. score.date
    y = @\printLine(text, x, y, width, font_size)

  @view\addEventListener("touch", gotoMainMenu)
  @view\addEventListener("tap", gotoMainMenu)
  @view

scene.exitScene = (event) =>
  storyboard.purgeScene()


scene\addEventListener( "createScene", scene )
scene\addEventListener( "exitScene", scene )

return scene
