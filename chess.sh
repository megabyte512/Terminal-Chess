#!/bin/bash

# TODO - make turn_r global

# Setup, dependencies
bgLight="\033[48;5;235m"
reset="\033[0m"

declare -A light_pieces
light_pieces["a2"]="♟"
light_pieces["b2"]="♟"
light_pieces["c2"]="♟"
light_pieces["d2"]="♟"
light_pieces["e2"]="♟"
light_pieces["f2"]="♟"
light_pieces["g2"]="♟"
light_pieces["h2"]="♟"
light_pieces["a1"]="♜"
light_pieces["b1"]="♞"
light_pieces["c1"]="♝"
light_pieces["d1"]="♛"
light_pieces["e1"]="♚"
light_pieces["f1"]="♝"
light_pieces["g1"]="♞"
light_pieces["h1"]="♜"

declare -A dark_pieces
dark_pieces["a7"]="♙"
dark_pieces["b7"]="♙"
dark_pieces["c7"]="♙"
dark_pieces["d7"]="♙"
dark_pieces["e7"]="♙"
dark_pieces["f7"]="♙"
dark_pieces["g7"]="♙"
dark_pieces["h7"]="♙"
dark_pieces["a8"]="♖"
dark_pieces["b8"]="♘"
dark_pieces["c8"]="♗"
dark_pieces["d8"]="♕"
dark_pieces["e8"]="♔"
dark_pieces["f8"]="♗"
dark_pieces["g8"]="♘"
dark_pieces["h8"]="♖"


draw_board() {  # just draws the board, same for both turns
  tput cup 3 7
  for _ in {1..4}; do
    for _ in {1..3}; do
      echo -e "${bgLight}       ${reset}       ${bgLight}       ${reset}       ${bgLight}       ${reset}       ${bgLight}       ${reset}       "
      tput cuf 7
    done
    for _ in {1..3}; do
      echo -e "${reset}       ${bgLight}       ${reset}       ${bgLight}       ${reset}       ${bgLight}       ${reset}       ${bgLight}       "
      tput cuf 7
    done
  done
  tput sgr0
}

print_coords() {  # prints the rank and file labels depending on turn
  local turn_r=$1
  tput sgr0
  if [[ $turn_r -eq 0 ]]; then
    for i in {0..7}; do
      tput cup $((4+3*i)) 4
      echo "$((8-i))"
    done
    tput cup 28 10
    echo "A      B      C      D      E      F      G      H"
  else
    for i in {0..7}; do
      tput cup $((4+3*i)) 4
      echo "$((1+i))"
    done
    tput cup 28 10
    echo "H      G      F      E      D      C      B      A"
  fi
}

convert_UCI() {  # changes simple <letter><number> coords into <number><number> coords
  true
}

turn_remainder() {  # returns the turn remainder with %. (e.g. 13%2=1, 54%2=0)
  local turn=$1
  turn_r=$((turn%2))
}

print_char() {  # actually prints the piece given the turn, unicode char, and position (currently in <letter><number> will probably change)
  local turn_r=$1
  local piece_type=$2
  local piece_pos=$3
  local temp_file=${piece_pos:0:1}
  local rank=${piece_pos:1:1}
  if [[ "$temp_file" =~ [a-h] ]]; then
    file=$(($(printf '%d' "'$temp_file") - 96))  # a rather elegant solution I found online to convert file to numbers 1-8 (using their ascii codes)
  fi
  # where we print the pieces depending on orientation of board.
  if [[ $turn_r -eq 0 ]]; then
    tput cup "$((28-3*rank))" "$((7*file+3))" 
  else
    tput cup "$((1+3*rank))" "$((66-7*file))"
  fi
  # print the piece with respective background
  if [[ $(((rank+file)%2)) -eq 0 ]]; then  # checking if it's on light or dark square
    echo -e "${reset}$piece_type"
  else
    echo -e "${bgLight}$piece_type"
  fi
}

print_all() {
  local turn_r=$1
  draw_board
  print_coords "$turn_r"
  for pos in "${!light_pieces[@]}"; do
    print_char "$turn_r" "${light_pieces[$pos]}" "$pos"
  done
  for pos in "${!dark_pieces[@]}"; do
    print_char "$turn_r" "${dark_pieces[$pos]}" "$pos"
  done

}



# Main logic

check_within_board() {
  local proposed_pos=$1
  # make sure within board
}

check_not_friendly() {
  local turn_r=$1
  local proposed_pos=$2
  #check black/white piece already occupies square
}

check_piece_moves() {
  local piece_type=$1
  local piece_pos=$2
  # is king, is queen, is pawn, rook...
}

check_if_valid_move() {  # in this order
  local turn_r=$1
  local move=$2
  check_valid_input
  check_within_board
  check_not_friendly
  check_piece_moves
}

move_piece() {
  local turn_r=$1
  local move=$2
  local from="${move:0:2}"
  local to="${move:2:2}"
  if [[ turn_r -eq 0 ]]; then
    unset 'dark_pieces['"$to"']'
    # Move the piece
    light_pieces["$to"]="${light_pieces[$from]}"
    unset 'light_pieces['"$from"']'
  else
    unset 'light_pieces['"$to"']'
    # Move the piece
    dark_pieces["$to"]="${dark_pieces[$from]}"
    unset 'dark_pieces['"$from"']'
  fi
}
# setting up terminal to clear and hide cursor
tput smcup
tput civis
clear
# upon exit, run these
trap 'tput cnorm; tput rmcup; exit 0' INT TERM EXIT

while true; do
  print_all "$turn_r"    # print board, pieces grid labels
  if [[ turn_r -eq 0 ]]; then
    tput cup 25 66       # move cursor to setup for input
    read -p -r "W > " move  # prompt for move, store in move var
    if check_if_valid_move "$turn_r" "$move"; then
      move_piece "$turn_r" "$move"
      turn_r=$turn_r+1
      turn=$turn+1
    else
      echo "no  . _ ."
    fi
  else
    tput cup 25 66
    read -p  -r "B > " move
    # move_piece "$turn_r" "$move"
    turn_r=$turn_r-1
    turn=$turn+1
  fi
  clear
done
