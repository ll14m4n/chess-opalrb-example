### Chess.

Features:

* Written in ruby
* Runs in browser using [Opal](http://opalrb.org/)
* Highlight valid moves.
* Follows the shades of  chess rules:  
    * [En-passant]( https://en.wikipedia.org/wiki/En_passant ) capture
    * Pawn [promotion](https://en.wikipedia.org/wiki/Promotion_(chess))
    * [fifty-move rule](https://en.wikipedia.org/wiki/Fifty-move_rule) 
    * Castling through check
* [PGN](https://en.wikipedia.org/wiki/Portable_Game_Notation) and [FEN](https://en.wikipedia.org/wiki/Forsyth-Edwards_Notation) notations output
* Import game from [FEN](https://en.wikipedia.org/wiki/Forsyth-Edwards_Notation) string
   
Run: 

```sh
$ git clone git@github.com:ll14m4n/chess-opalrb-example.git
$ cd chess-opalrb-example
$ bundle install 
$ bundle exec rackup
```

Open `localhost:9292`