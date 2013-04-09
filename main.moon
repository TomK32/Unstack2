--
-- Unstack2 main.lua

export analytics = require ("lib.game_analytics")
analytics.isDebug = false
analytics.submitSystemInfo = true
analytics.archiveEvents = true
analytics\init({
  game_key: "738db647ca81d62ce54bddd8dc2d6f21",
  secret_key: "1332438b04ed432511601f15ac8225500d3039ee",
  build: require("version")
})

-- log events
analytics.newEvent("game", {event_id: "loading"})

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

  reset: ->
    game.time_remaining = nil
    game.last_target_time = 0
}


display.setStatusBar( display.HiddenStatusBar )

export storyboard = require "storyboard"
storyboard.purgeOnSceneChange = true
storyboard.gotoScene("scenes.intro")


