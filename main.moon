--
-- Unstack2 main.lua

require ("lib.game_analytics")
require 'block'
GameAnalytics.newEventWithoutDelay = GameAnalytics.newEvent
GameAnalytics.newEvent = (category, ...) ->
  opts = ...
  timer.performWithDelay 1, ->
    analytics.newEventWithoutDelay(category, opts)

export analytics = GameAnalytics
analytics.isDebug = false
analytics.submitSystemInfo = true
analytics.archiveEvents = true
analytics.init(require('conf.analytics'))

-- log events
analytics.newEvent("design", {event_id: "loading"})

block_size = math.floor(display.contentWidth / 10 / 8) * 8
export game = {
  -- apply /8*8 on block size to get nicer numbers
  block_size: block_size,
  level: 0,
  lvlString: ->
    string.format('%.4f', game.level)
  score: 0,
  running_score: 0, -- to increase the score with some easing
  width: math.floor(display.contentWidth / block_size)
  height: math.floor(display.contentHeight / block_size) - 4


  field: nil,
  gestureBlock: Block({}),
  targetBlock: nil,
  last_target_time: 0,
  sounds: require('sounds')

  getTimeRemaining: (now) ->
    return now + math.ceil(3 * math.sqrt(game.field\width() * game.field\height()) / 30) * 30000

  reset: ->
    game.running = true
    game.running_score = game.score
    game.score_level_start = game.score
    game.time_remaining = nil
    game.last_target_time = nil
}

display.setStatusBar( display.HiddenStatusBar )

export storyboard = require "storyboard"
storyboard.purgeOnSceneChange = true
storyboard.gotoScene("scenes.intro")


