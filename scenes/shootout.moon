--  Unstack2 Field
--
--  Copyright 2011-2013 Ananasblau.com. All rights reserved.

scene = storyboard.newScene('Shootout')
widget = require "widget"

scene.resetGun = () =>
  @gun = {
    fire_frequence: 200,
    shots: 50,
    cost_per_shot: 3
  }

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
  game.score -= scene.gun.cost_per_shot
  scene.gun.shots -= 1

  x = event.x - game.field.group.x
  y = event.y - game.field.group.y
  block_x = math.ceil(x / game.block_size)
  block_y = math.ceil(y / game.block_size)
  block = game.field\get(block_x, block_y)
  if not block
    analytics.newEvent("design", {event_id: "shooting:failure", area: game.lvlString(), value: time_remaining})
    return true

  game.sounds.play('explosion')

  game.field\substractBlock(block_x, block_y)
  analytics.newEvent("design", {event_id: "shooting:success", area: game.lvlString(), value: time_remaining})
  scene.createShot(block_x, block_y, block)

  -- make score big and grow back to normal size
  game.score_display.size = game.block_size + (game.score - game.running_score)
  transition.to(game.score_display, { size: game.block_size})

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
    transition.to(rect, { time: 5000, alpha: 0, transition: easing.inExpo })
    scene.shots_group\insert(rect)

scene.updateTimerDisplay = (event) ->
  t = event.time / game.time_remaining
  timer_color = nil
  text = ''
  if game.time_remaining - event.time < 10000 -- 10 secs
    text = string.format("%.1f", (game.time_remaining - event.time) / 1000)
  else
    text = math.floor((game.time_remaining - event.time) / 1000)
  game.timer_display.text = text
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
  game.score_level_start = game.score
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

  game.level_display = display.newText('lvl ' .. game.level, 0, game.block_size * 2, native.systemFontBold, game.block_size)
  rightAlignText(game.level_display, display.contentWidth)


  game.timer_display = display.newText(' ', 0, game.block_size * 2, native.systemFontBold, game.block_size)

  game.score_display = display.newText(game.score, 0, game.block_size, native.systemFontBold, game.block_size)

  @view\insert(game.timer_display)
  @view\insert(game.score_display)
  @view\insert(game.level_display)
  @view

scene.enterScene = (event) =>
  game.reset()
  @resetGun()
  game.level += 1
  if @view.end_level_dialog
    @view.end_level_dialog\removeSelf()
  game.sounds.play('level_start')
  analytics.newEvent('design', {event_id: 'shootout:new', area: game.lvlString()})
  game.level_display.text = 'lvl ' .. game.level

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

