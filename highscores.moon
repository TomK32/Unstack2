
export json = require 'json'

export class Highscores

  highscores_file: 'unstack2-highscores.txt'
  scores_to_keep: 10

  new: =>
    @highscores = {}
    @total_games = 0
    @total_score = 0
    @readLocalHighscores()
    return @

  insert: (score) =>
    table.insert(@highscores, score)
    @total_games += 1
    @total_score += score.score
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

  fileContent: =>
    {
      highscores: @highscores,
      total_score: @total_score,
      total_games: @total_games
    }
  saveLocalHighscores: =>
    file = @highscoresFile 'w', (file) => file\write( json.encode(@fileContent()) )

  readLocalHighscores: =>
    file = @highscoresFile 'r', (file) => @content = json.decode( file\read("*a") )
    if not @content
      @highscores = {}
      return
    for k,v in pairs(@content)
      @[k] = v

