--  Unstack2 Field
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.

scene = storyboard.newScene('Field')
widget = require "widget"
require 'hit_block'

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
  game.last_target_time = os.time()

gestureShape = (event) ->
  if not game.running
    return
  if event.phase == 'began'
    analytics.newEvent("design", {event_id: 'gesturing:begin'})
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
  if scene.hint
    scene.hint\removeSelf()

  -- add to the shape we draw
  -- NOTE: this shape fits into the Field, for comparing with the
  --       wanted block it needs to be normalized first

  if game.targetBlock and game.gestureBlock\isLike(game.targetBlock) then
    time_for_gesture = os.time() - game.last_target_time
    analytics.newEvent("design", {event_id: "gesturing:success", area: 'lvl' .. game.level, value: time_remaining})
    game.field\substract(game.gestureBlock)
    game.score += math.ceil(20 - (time_for_gesture)/1000)
    createTarget()
    scene.needsHint = false
    game.sounds.play('shape_solved')
  elseif event.phase == 'ended'
    game.sounds.play('shape_failed')
    analytics.newEvent("design", {event_id: "gesturing:failed", area: 'lvl' .. game.level})
  return true


scene.updateTimerDisplay = (event) ->
  t = event.time / game.time_remaining
  timer_color = nil
  game.timer_display.text = math.floor((game.time_remaining - event.time) / 1000)
  if t < 0.5
    timer_color = {255, 255, 255, 255}
  else
    timer_color = {255, 150 * (2-2*t),  0,255}
  game.timer_display\setTextColor(unpack(timer_color))

  leftAlignText(game.timer_display, game.block_size * 4)

scene.updateScoreDisplay = (event) ->
  if game.running_score + 3 <= game.score
    game.running_score += 3
  elseif game.running_score + 1 <= game.score
    game.running_score += 1
  elseif game.running_score > game.score
    game.running_score = (game.score + game.running_score) / 2
  game.score_display.text = math.floor(game.running_score)
  leftAlignText(game.score_display, game.block_size * 4)

scene.gameLoop = (event) ->
  if not game.running
    return
  if not game.time_remaining
    game.time_remaining = event.time + math.ceil(3 * math.sqrt(game.field\width() * game.field\height()) / 30) * 30000
  if game.time_remaining < event.time
    scene.endLevel()
    return true
  scene.updateScoreDisplay(event)
  scene.updateTimerDisplay(event)

scene.endLevel = () ->
  blocks_left = game.field\blocksLeft()
  game.score -= math.floor(math.sqrt(blocks_left))
  game.score += game.level
  game.running_score = game.score
  Runtime\removeEventListener("enterFrame", gameLoop)
  scene.updateScoreDisplay()
  analytics.newEvent('design', {event_id: 'level.ended', area: 'lvl' .. game.level, value: blocks_left})

  game.running = false
  end_level_dialog = display.newGroup()

  x = display.contentWidth * 0.5
  y = game.block_size * 4.5
  background = display.newRect(game.block_size * 1.5, y, display.contentWidth - game.block_size * 3, display.contentHeight - game.block_size * 5)
  background\setFillColor(0,0,0,200)
  end_level_dialog\insert(background)
  y += game.block_size * 2

  score_text = "You scored " .. math.floor(game.score - game.score_level_start)
  score_text = display.newText(score_text, 0, y, native.systemFontBold, 16)
  score_text.x = x
  end_level_dialog\insert(score_text)

  y += score_text.height + game.block_size

  next_button = widget.newButton({
    label: "Next Level",
    labelColor: { default: {0}, over: {0} },
    onRelease: (event) ->
      storyboard.purgeScene()
      storyboard.gotoScene("scenes.field")
      return true
  })
  next_button.x = x
  next_button.y = y
  end_level_dialog\insert(next_button)
  y += next_button.height * 2

  menu_button = widget.newButton({
    label: "Go To Menu",
    labelColor: { default: {0}, over: {0} },
    onRelease: (event) ->
      storyboard.gotoScene("scenes.menu", "fade", 50)
      analytics.newEvent("design", {event_id: "game:end"})
      return true
  })
  menu_button.x = x
  menu_button.y = y

  end_level_dialog\insert(menu_button)
  scene.view.end_level_dialog = end_level_dialog
  scene.view\insert(end_level_dialog)

scene.giveHint = =>
  return if not scene.needsHint
  scene.hint = display.newGroup()
  scene.field_group\insert(scene.hint)
  hintBlock = HintBlock(game.targetBlock\normalize(), scene.hint, game.field)
  timer.performWithDelay 3000, => scene.hint\removeSelf()


-- Called when the scene's view does not exist:
scene.createScene = (event) =>
  -- view size will take full width but leave a few block on the top
  group = display.newGroup()
  @field_group = group
  @view\insert(group)
  group.y = 4 * game.block_size

  background = display.newImageRect( "images/menu_background.png", display.contentWidth, display.contentHeight )
  background\setReferencePoint( display.TopLeftReferencePoint )
  background.x, background.y = 0, 0
  background.blendMode = 'add'
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
  scene.needsHint = true
  if scene.hint
    scene.hint\removeSelf()

  game.reset()
  game.level += 1
  if @view.end_level_dialog
    @view.end_level_dialog\removeSelf()
  game.reset()
  game.sounds.play('level_start')
  analytics.newEvent('design', {event_id: 'level.new', area: 'lvl' .. game.level})
  game.level_display.text = 'lvl ' ..game.level

  game.field = Field.random(@field_group, game.level, game.width, game.height)
  game.field.target = game.target_group

  createTarget()
  timer.performWithDelay 1, -> Runtime\addEventListener("enterFrame", scene.gameLoop)
  timer.performWithDelay 3000, scene.giveHint

scene.exitScene = () =>
  Runtime\removeEventListener("enterFrame", scene.gameLoop)
  if game.field
    game.field\removeSelf()
  --storyboard.purgeScene()


scene\addEventListener( "createScene", scene )
scene\addEventListener( "enterScene", scene )
scene\addEventListener( "exitScene", scene )
--Runtime\addEventListener( "enterFrame", game.field.draw)


return scene


