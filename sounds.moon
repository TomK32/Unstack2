
sounds = {}
sounds.level_start = audio.loadSound('sounds/level_start.mp3')
sounds.shape_failed = {
  audio.loadSound('sounds/shape_failed1.mp3')
}
sounds.shape_solved = {
  audio.loadSound('sounds/shape_solved1.mp3'),
  audio.loadSound('sounds/shape_solved2.mp3'),
  audio.loadSound('sounds/shape_solved3.mp3')
}
sounds.play = (file) ->
  file = sounds[file]
  if type(file) == 'table'
    file = file[math.ceil(math.random() * #file)]
  audio.play(file)

return sounds
