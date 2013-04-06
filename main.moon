--
-- Unstack2 main.lua

require 'field'

export game = {
  -- apply /8*8 on block size to get nicer numbers
  block_size: math.floor(display.contentWidth / 10 / 8) * 8,
  level: 1,
  score: 0,
  running_score: 0, -- to increase the score with some easing

  gestureBlock: Block({})
  targetBlock: nil,
  last_target_time: 0

}


display.setStatusBar( display.HiddenStatusBar )

storyboard = require "storyboard"

storyboard.gotoScene("scenes.menu")


