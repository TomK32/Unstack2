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


scene.skipTarget = (event) ->
  -- keep player from going berserk
  if game.last_target_time + 1 > os.time()
    return
  game.score -= 20
  game.sounds.play('shape_failed')
  scene.createTarget()
  return false

scene.createTarget = () ->
  -- the block we need to mark
  if game.targetBlock
    game.targetBlock\removeSelf()
  gradient = graphics.newGradient({255,200,0}, {255, 255,0})
  game.targetBlock = Field(Block.random().shape, game.target_group, nil, {gradient})
  game.last_target_time = os.time()
  timer.performWithDelay 1000, -> game.target_group\addEventListener("tap", scene.skipTarget )


gestureShape = (event) ->
  if not game.running
    return
  if event.phase == 'ended'
    scene.resetGestureTrail()
  if event.phase == 'began'
    analytics.newEvent("design", {event_id: 'gesturing:begin'})
    game.gestureBlock = Block({}) -- the block we draw
  --table.insert(game.gestureShapePoints, {event.x, event.y})
  x = event.x - game.field.group.x
  y = event.y - game.field.group.y
  block_x = math.ceil(x / game.block_size)
  block_y = math.ceil(y / game.block_size)
  block = game.field\get(block_x, block_y)
  if not block
    scene.errorGesturing(event)
    return true
  elseif game.gestureBlock\get(block_x, block_y)
    -- nothing to do
    return true

  if event.phase == 'began' -- we needed a block first
    game.gesturing = true
  if not game.gesturing
    return

  -- keep track of wether we can give a bonus for having the swiping all blocks of the colour
  if not game.gestureBlock.last_color_num
    game.gestureBlock.last_color_num = block.color_num
    game.gestureBlock.color_bonus = true
  if game.gestureBlock.color_bonus
    game.gestureBlock.color_bonus = game.gestureBlock.last_color_num == block.color_num

  -- add to the shape we draw
  game.gestureBlock\set(block_x, block_y, 1)
  scene.createGestureTrail(block_x, block_y)

  if scene.hint
    scene.hint\removeSelf()


  if game.targetBlock and game.gestureBlock\isLike(game.targetBlock) then
    game.field\substract(game.gestureBlock)
    time_for_gesture = os.time() - game.last_target_time
    analytics.newEvent("design", {event_id: "gesturing:success", area: game.lvlString(), value: time_remaining})
    bonus = 1
    if game.gestureBlock.color_bonus
      bonus = 2
      bonus_text = display.newText("2x bonus", 0, game.block_size, native.systemFontBold, 16)
      scene.view\insert(bonus_text)
      rightAlignText(bonus_text, display.contentWidth)
      transition.to(bonus_text, {alpha: 0, time: 1000, onComplete: => self\removeSelf()})

    game.score += (math.ceil(20 - time_for_gesture) + game.gestureBlock\weight()) * bonus
    game.gestureBlock = Block({})

    -- make score big and grow back to normal size
    game.score_display.size = game.block_size + (game.score - game.running_score)
    transition.to(game.score_display, { size: game.block_size})

    scene.createTarget()
    scene.needsHint = false
    game.sounds.play('shape_solved')
    game.gesturing = false
  return true

scene.errorGesturing = (event) ->
  scene.resetGestureTrail()
  game.gestureBlock = Block({})
  if not game.gesturing or (game.last_gesture_error and game.last_gesture_error + 1000 > event.time)
    return false
  game.last_gesture_error = event.time
  scene.error_background\setFillColor(255,0,0,255)
  transition.to(scene.error_background, {time: 500, alpha: 0,
    onComplete: ->
      scene.error_background.alpha = 1.0
      scene.error_background\setFillColor(255,0,0,0)

  })
  analytics.newEvent("design", {event_id: "gesturing:failed", area: game.lvlString()})
  game.sounds.play('shape_failed')

scene.createGestureTrail = (x, y) ->
  for i = 1, 1 do
    rect = display.newRect(unpack(Field.blockToRect(x,y)))
    --rect.blendMode = 'add'
    rect\setFillColor(255,255,255,200)
    transition.to(rect, {
      time: 500, rotation: 90
      height: game.block_size / 4, width: game.block_size / 4,
    })
    transition.to(rect, {
      time: 2000, alpha: 0,
      transition: easing.inExpo,
      onComplete: =>
        if @.removeSelf
          @\removeSelf()
    })
    game.gesture_group\insert(rect)

scene.resetGestureTrail = ->
  if game.gesture_group and game.gesture_group.removeSelf
    game.gesture_group\removeSelf()
  game.gesture_group = display.newGroup()
  scene.field_group\insert(game.gesture_group)

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
    game.time_remaining = game.getTimeRemaining(event.time)
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
  analytics.newEvent('design', {event_id: 'level.ended', area: game.lvlString(), value: blocks_left})

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

  -- setup playing field
  -- needs a background so we get touch events when entering empty space
  @error_background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  @error_background\setFillColor(255,0,0,0)
  group\insert(@error_background)
  group\addEventListener( "touch", gestureShape )

  group.x = (display.contentWidth - game.width * game.block_size) / 2

  game.target_group = display.newGroup()
  game.target_group.y = game.block_size / 2
  game.target_group.x = game.block_size / 2

  -- needs a background to have a decent tap area
  background = display.newRect(0, 0, game.block_size * 3, game.block_size * 3)
  background\setFillColor(0,0,0,1)
  game.target_group\insert(background)

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
  scene.resetGestureTrail()
  scene.needsHint = true
  if scene.hint
    scene.hint\removeSelf()

  game.reset()
  game.level += 1
  if @view.end_level_dialog
    @view.end_level_dialog\removeSelf()
  game.reset()
  game.sounds.play('level_start')
  analytics.newEvent('design', {event_id: 'level.new', area: game.lvlString()})
  game.level_display.text = 'lvl ' .. game.level

  game.field = Field.random(@field_group, game.level, game.width, game.height)
  game.field.target = game.target_group

  scene.createTarget()
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


