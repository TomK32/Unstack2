
export json = require 'json'

export class Highscores

  highscores_file: 'unstack2-highscores.txt'
  scores_to_keep: 10

  new: =>
    @highscores = {}
    @readLocalHighscores()
    return @

  insert: (score) =>
    table.insert(@highscores, score)
    @tidyHighscores()
    @saveLocalHighscores()

  tidyHighscores: () =>
    count = 0
    min = nil
    for i, score in ipairs(@highscores)
      count += 1
      if not min or score.score < min.score
        min = score
        min.pos = i
    if count > @scores_to_keep and min
      table.remove(@highscores, min.pos)
      if count > @scores_to_keep + 1
        @tidyHighscores()
    @sortHighscores()

  sortHighscores: =>
    table.sort(@highscores, (a,b) -> return a.score > b.score)

  highscoresFile: (right, block) =>
    file = io.open(system.pathForFile(@highscores_file, system.DocumentsDirectory), right)
    if not file
      return
    block(self, file)
    io.close(file)

  saveLocalHighscores: =>
    file = @highscoresFile 'w', (file) => file\write( json.encode(@highscores) )

  readLocalHighscores: =>
    file = @highscoresFile 'r', (file) => @highscores = json.decode( file\read("*a") )
    if not @highscores
      @highscores = {}

