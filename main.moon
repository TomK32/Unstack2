--
-- Unstack2 main.lua

licensing = require "licensing"
licensing.init( "google" )

licensingListener = ( event ) ->
  verified = event.isVerified
  if not event.isVerified
    print("Pirates!!!")

licensing.verify( licensingListener )

require ("lib.game_analytics")
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

require 'field'

block_size = math.floor(display.contentWidth / 10 / 8) * 8
export game = {
  -- apply /8*8 on block size to get nicer numbers
  block_size: block_size,
  level: 1,
  score: 0,
  running_score: 0, -- to increase the score with some easing
  time_for_level: 1000 * 10
  width: math.floor(display.contentWidth / block_size)
  height: math.floor(display.contentHeight / block_size) - 4


  field: nil,
  gestureBlock: Block({}),
  targetBlock: nil,
  last_target_time: 0,
  sounds: require('sounds')

  reset: ->
    game.time_remaining = nil
    game.last_target_time = 0
}

game.sounds.play('music')
display.setStatusBar( display.HiddenStatusBar )

export storyboard = require "storyboard"
storyboard.purgeOnSceneChange = true
storyboard.gotoScene("scenes.intro")


