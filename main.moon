--
-- Unstack2 main.lua

export game = {
  -- apply /8*8 on block size to get nicer numbers
  block_size: math.floor(display.contentWidth / 10 / 8) * 8,
  level: 1
}


display.setStatusBar( display.HiddenStatusBar )

storyboard = require "storyboard"

storyboard.gotoScene("scenes.menu")


