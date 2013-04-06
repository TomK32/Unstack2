--  Unstack2 Field
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.
-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

scene = storyboard.newScene('Field')
widget = require "widget"


rightAlignText = (text, x) ->
  text.x = x - text.width / 2 - game.block_size * 0.2

leftAlignText = (text, x) ->
  text.x = x + text.width / 2 + game.block_size * 0.2

createTarget = () ->
  -- the block we need to mark
  if game.targetBlock
    game.targetBlock\removeSelf()
  gradient = graphics.newGradient({255,200,0}, {255, 255,0})
  game.targetBlock = Field(Block.random().shape, game.target_group, nil, {gradient})


gestureShape = (event) ->
  game.last_movement = event.time
  if event.phase == 'began'
    game.gestureShapePoints = {} -- takes {x, y} pixel coords
    game.gestureBlock = Block({}) -- the block we draw
  --table.insert(game.gestureShapePoints, {event.x, event.y})
  x = event.x - game.field.group.x
  y = event.y - game.field.group.y
  block_x = math.ceil(x / game.block_size)
  block_y = math.ceil(y / game.block_size)
  block = game.field\get(block_x, block_y)
  if not block
    game.gestureBlock = Block({})
    return true
  elseif game.gestureBlock\get(block_x, block_y)
    -- nothing to do
    return true
  game.gestureBlock\set(block_x, block_y, 1)

  -- add to the shape we draw
  -- NOTE: this shape fits into the Field, for comparing with the
  --       wanted block it needs to be normalized first

  if game.targetBlock and game.gestureBlock\isLike(game.targetBlock) then
    game.field\substract(game.gestureBlock)
    game.score += 20 - (event.time - game.last_target_time)/1000
    game.last_target_time = event.time
    createTarget()
  return true


updateTimerDisplay = (event) ->
  t = event.time / game.time_remaining
  timer_color = nil
  game.timer_display.text = math.floor((game.time_remaining - event.time) / 500)
  if t < 0.5
    timer_color = {255, 255, 255, 255}
  else
    timer_color = {255, 150 * (2-2*t),  0,255}
  game.timer_display\setTextColor(unpack(timer_color))

  leftAlignText(game.timer_display, game.block_size * 4)

updateScoreDisplay = (event) ->

  if game.running_score + 3 <= game.score
    game.running_score += 3
  elseif game.running_score + 1 <= game.score
    game.running_score += 1
  elseif game.running_score > game.score
    game.running_score = (game.score + game.running_score) / 2
  game.score_display.text = math.floor(game.running_score)
  leftAlignText(game.score_display, game.block_size * 4)

gameLoop = (event) ->
  if not game.time_remaining
    game.time_remaining = event.time + game.time_for_level
  if game.time_remaining < event.time
    game.score -= math.sqrt(game.field\blocksLeft())
    game.score += game.level
    Runtime\removeEventListener("enterFrame", gameLoop)
    game.reset()
    game.level += 1
    storyboard.reloadScene()
    return true
  updateScoreDisplay(event)
  updateTimerDisplay(event)


-- Called when the scene's view does not exist:
scene.createScene = (event) =>
  -- view size will take full width but leave a few block on the top
  group = display.newGroup()
  @field_group = group
  @view\insert(group)
  group.y = 4 * game.block_size
  game.width = math.floor(display.contentWidth / game.block_size)
  game.height = math.floor(display.contentHeight / game.block_size) - 4

  background = display.newRect(0, 0, game.width * game.block_size, game.height * game.block_size)
  background\setFillColor(30,30,30,255)
  group\insert(background)

  -- setup playing field
  group\addEventListener( "touch", gestureShape )

  group.x = (display.contentWidth - game.width * game.block_size) / 2

  game.target_group = display.newGroup()
  game.target_group.y = game.block_size / 2
  game.target_group.x = game.block_size / 2

  game.level_display = display.newText('lvl ' .. game.level, 0, game.block_size * 2, native.systemFontBold, game.block_size)
  rightAlignText(game.level_display, display.contentWidth)


  game.timer_display = display.newText(' ', 0, game.block_size * 2, native.systemFontBold, game.block_size)

  game.score_display = display.newText(game.score, 0, game.block_size, native.systemFontBold, game.block_size)


  @view\insert(game.timer_display)
  @view\insert(game.score_display)
  @view\insert(game.level_display)
  @view\insert(game.target_group)
  @view

scene.enterScene = (event) =>
  timer.performWithDelay 1, => Runtime\addEventListener("enterFrame", gameLoop)
  game.level_display.text = 'lvl ' ..game.level

  if game.field
    game.field\removeSelf()
  game.field = Field.random(@field_group, game.level, game.width, game.height)
  game.field.target = game.target_group

  createTarget()
  game.reset()

scene.exitScene = () =>
  --storyboard.purgeScene()


scene\addEventListener( "createScene", scene )
scene\addEventListener( "enterScene", scene )
scene\addEventListener( "exitScene", scene )
--Runtime\addEventListener( "enterFrame", game.field.draw)


return scene


