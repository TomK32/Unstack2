--  Unstack2 Field
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.

scene = storyboard.newScene('Shootout')
widget = require "widget"

scene.resetGun = () =>
  @gun = {
    fire_frequence: 200,
    shots: 10
    score_per_hit: 3
    changeShots: (diff) ->
      scene.gun.shots += diff
      scene.shots_display.text = scene.gun.shots
  }

scene.timeRemaining = (time) ->
  -- 500ms for every shot
  return time + 500 * scene.gun.shots

rightAlignText = (text, x) ->
  text.x = x - text.width / 2 - game.block_size * 0.2

leftAlignText = (text, x) ->
  text.x = x + text.width / 2 + game.block_size * 0.2

tapField = (event) ->
  if scene.last_shot and scene.last_shot + scene.gun.fire_frequence > event.time
    return true
  if not game.running
    return true

  scene.last_shot = event.time
  game.sounds.play('shot')
  scene.gun.changeShots(-1)

  x = event.x - game.field.group.x
  y = event.y - game.field.group.y
  block_x = math.ceil(x / game.block_size)
  block_y = math.ceil(y / game.block_size)
  block = game.field\get(block_x, block_y)
  if not block
    analytics.newEvent("design", {event_id: "shooting:failure", area: game.lvlString(), value: time_remaining})
    game.color_bonus = nil -- different than the one in the field scene
    game.last_color_num = nil
    return true
  if block.removed -- hitting one block twice in a very very short time
    return

  game.sounds.play('explosion')

  -- bonus multiplier
  if game.last_color_num and game.last_color_num == block.color_num
    game.color_bonus = (game.color_bonus or 1) + 1
    if game.color_bonus > 1
      bonus_text = display.newText( game.color_bonus .. "x bonus", 0, game.block_size, native.systemFontBold, 16)
      scene.view\insert(bonus_text)
      rightAlignText(bonus_text, display.contentWidth)
      transition.to(bonus_text, {alpha: 0, time: 1000, onComplete: => self\removeSelf()})
  else
    game.last_color_num = block.color_num
    game.color_bonus = 1


  game.score += scene.gun.score_per_hit * (game.color_bonus or 1)
  game.field\substractBlock(block_x, block_y)
  scene.createShot(block_x, block_y, block)

  analytics.newEvent("design", {event_id: "shooting:success", area: game.lvlString(), value: time_remaining})

  -- make score big and grow back to normal size
  scene.score_display.size = game.block_size + (game.score - game.running_score)
  transition.to(scene.score_display, { size: game.block_size})


  game.sounds.play('shot_success')

  if game.field\cleared()
    scene.endLevel(event)
  return true

scene.createShot = (x, y, block) ->
  color = Field.colors[block.color_num]
  yellow_color = graphics.newGradient({255,200,0}, {255, 255,0})

  for i, coord in pairs({{1,1},{1,-1},{-1,1},{-1,-1}}) do
    seed = (game.block_size * math.random())
    rect = display.newRect(unpack(Field.blockToRect(x,y)))
    --rect.blendMode = 'add'
    if math.random() > 0.5
      rect\setFillColor(color)
    else
      rect\setFillColor(yellow_color)
    transition.to(rect, {
      time: 500,
      height: game.block_size / 4, width: game.block_size / 4,
      x: (x - 0.5) * game.block_size + seed * coord[1],
      y: (y - 0.5) * game.block_size + seed * coord[2]
    })
    transition.to(rect, { time: 5000, alpha: 0, transition: easing.inQuad })
    scene.shots_group\insert(rect)

scene.updateTimerDisplay = (event) ->
  t = event.time / game.time_remaining
  timer_color = nil
  text = ''
  if game.time_remaining - event.time < 10000 -- 10 secs
    text = string.format("%.1f", (game.time_remaining - event.time) / 1000)
  else
    text = math.floor((game.time_remaining - event.time) / 1000)
  scene.timer_display.text = text
  if t < 0.5
    timer_color = {255, 255, 255, 255}
  else
    timer_color = {255, 150 * (2-2*t),  0,255}
  scene.timer_display\setTextColor(unpack(timer_color))

  leftAlignText(scene.timer_display, game.block_size * 4)

scene.updateScoreDisplay = (event) ->
  if game.running_score + 3 <= game.score
    game.running_score += 3
  elseif game.running_score + 1 <= game.score
    game.running_score += 1
  elseif game.running_score > game.score
    game.running_score = (game.score + game.running_score) / 2
  scene.score_display.text = math.floor(game.running_score)
  leftAlignText(scene.score_display, game.block_size * 4)

scene.gameLoop = (event) ->
  if not game.running
    return
  if not game.time_remaining
    game.time_remaining = scene.timeRemaining(event.time)
  if game.score <= 0 or scene.gun.shots <= 0
    scene.endLevel(event)
    return true
  if game.time_remaining < event.time
    scene.endLevel(event)
    return true
  scene.updateScoreDisplay(event)
  scene.updateTimerDisplay(event)

scene.endLevel = (event) ->
  blocks_left = game.field\blocksLeft()
  game.score -= blocks_left
  if game.time_remaining > event.time
    game.score += (game.time_remaining - event.time) / 1000 * 20
  game.running_score = game.score
  Runtime\removeEventListener("enterFrame", gameLoop)
  scene.updateScoreDisplay()
  analytics.newEvent('design', {event_id: 'shootout:ended', area: game.lvlString(), value: blocks_left})

  game.running = false
  end_level_dialog = display.newGroup()

  x = display.contentWidth * 0.5
  y = game.block_size * 4.5
  background = display.newRect(game.block_size * 1.5, y, display.contentWidth - game.block_size * 3, display.contentHeight - game.block_size * 5)
  background\setFillColor(0,0,0,200)
  end_level_dialog\insert(background)
  y += game.block_size
  
  score_text = "You scored " .. math.floor(game.score - game.score_level_start)
  score_text = display.newText(score_text, 0, y, native.systemFontBold, 16)
  score_text.x = x
  end_level_dialog\insert(score_text)
  y += score_text.height + game.block_size

  game.highscores\insert({score: game.score - game.score_level_start, date: os.date('%F'), level: game.level})

  next_button = widget.newButton({
    label: "Next Level",
    labelColor: { default: {0}, over: {0} },
    top: y,
    left: x,
    onRelease: (event) ->
      storyboard.purgeScene()
      storyboard.gotoScene("scenes.field")
      return true
  })
  next_button.x = x
  next_button.y = y
  end_level_dialog\insert(next_button)
  y += next_button.height + game.block_size

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

-- Called when the scene's view does not exist:
scene.createScene = (event) =>
  @resetGun()
  -- view size will take full width but leave a few block on the top
  group = display.newGroup()
  @field_group = group
  @view\insert(group)
  group.y = 4 * game.block_size

  @shots_group = display.newGroup()
  @field_group\insert(@shots_group)
  
  -- setup playing field
  -- needs a background so we get touch events when entering empty space
  @error_background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  @error_background\setFillColor(255,0,0,0)
  group\insert(@error_background)
  group\addEventListener( "tap", tapField )
  group\addEventListener( "touch", tapField )

  group.x = (display.contentWidth - game.width * game.block_size) / 2

  -- needs a background to have a decent tap area
  background = display.newRect(0, 0, game.block_size * 3, game.block_size * 3)
  background\setFillColor(0,0,0,1)

  scene.level_display = display.newText('lvl ' .. game.level, 0, game.block_size * 2, native.systemFontBold, game.block_size)
  rightAlignText(scene.level_display, display.contentWidth)


  scene.timer_display = display.newText(' ', 0, game.block_size * 2, native.systemFontBold, game.block_size)

  scene.score_display = display.newText(game.score, 0, game.block_size, native.systemFontBold, game.block_size)

  scene.shots_display = display.newText(scene.gun.shots, game.block_size, game.block_size, native.systemFontBold, game.block_size)

  @view\insert(scene.timer_display)
  @view\insert(scene.score_display)
  @view\insert(scene.shots_display)
  @view\insert(scene.level_display)
  @view

scene.enterScene = (event) =>
  @resetGun()
  game.score_level_start = game.score
  game.reset()
  game.level += 1
  if @view.end_level_dialog
    @view.end_level_dialog\removeSelf()
  game.sounds.play('level_start')
  analytics.newEvent('design', {event_id: 'shootout:new', area: game.lvlString()})
  scene.level_display.text = 'lvl ' .. game.level

  game.field = Field(game.field.shape, @field_group, game.level)

  timer.performWithDelay 1, -> Runtime\addEventListener("enterFrame", scene.gameLoop)

scene.exitScene = () =>
  Runtime\removeEventListener("enterFrame", scene.gameLoop)
  if game.field
    game.field\removeSelf()

scene\addEventListener( "createScene", scene )
scene\addEventListener( "enterScene", scene )
scene\addEventListener( "exitScene", scene )

return scene

