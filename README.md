# About

This is a little chess game for the terminal that I made for myself. 2-player, so you need a friend. I've toyed with the idea of writing a bot to play against, but am not quite sure how I'd implement it with my current code structure. As it stands,
however, this terminal chess game is written exclusively in bash and features castling, pawn promotion (just to queens :( sorry if you wanted to chess mog your friend and under-promote), UCI coordinates that flip with perspective, displayed captured pieces
and material difference.

## Ideas

* Bots!
  * Different levels of difficulty, of course
  * Could judge moves based on material difference and evaluate positions
* Timer for players
  * It's kind of hard to get the hang of typing in UCI coordinates, so not the best idea I've had
* Mouse compatibility for easier moving
* Undo move function
* Online play
* Polish
  * En passant
  * Other promotion options
  * Corrected castling
    * Only when it's rook and king's first move
    * Can't castle out of check (working inconsistently right now)
