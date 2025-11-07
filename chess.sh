#!/bin/bash

# Setup, dependencies
bgLight="\033[48;5;235m"
reset="\033[0m"
turn_r=0  # global variable that flips every time the turn is handed off

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

convert_UCI_to_coords() {  # converts <letter><number> to <number><number>
  local UCI=$1
  local file="${UCI:0:1}"
  local rank="${UCI:1:1}"
  if [[ "$file" =~ [a-h] ]]; then
    num_file=$(($(printf '%d' "'$file") - 96))  # a rather elegant solution I found online to convert file to numbers 1-8 (using their ascii codes)
  fi
  echo "$num_file $rank"
}

turn_remainder() {  # returns the turn remainder with %. (e.g. 13%2=1, 54%2=0)
  local turn=$1
  turn_r=$((turn%2))
}

print_char() {  # actually prints the piece given the turn, unicode char, and position (currently in <letter><number> will probably change)
  local piece_type=$1
  local piece_pos=$2
  converted_coords=$(convert_UCI_to_coords "$piece_pos")
  read file rank <<< "$converted_coords"
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
  draw_board
  print_coords
  for pos in "${!light_pieces[@]}"; do
    print_char "${light_pieces[$pos]}" "$pos"
  done
  for pos in "${!dark_pieces[@]}"; do
    print_char "${dark_pieces[$pos]}" "$pos"
  done
}



# Main logic
check_valid_input() {  # checks for correct length
  local move=$1
  if [[ ${#move} -gt 4 || ${#move} -lt 4 ]]; then
    return 1
  fi
  return 0
}

check_within_board() {  # make sure within board
  local proposed_pos=$1
  local file="${proposed_pos:0:1}"
  local rank="${proposed_pos:1:1}"
  if [[ "$rank" -lt 1 || "$rank" -gt 8 ]]; then
    return 1
  fi
  case $file in
    'a') return 0;;
    'b') return 0;;
    'c') return 0;;
    'd') return 0;;
    'e') return 0;;
    'f') return 0;;
    'g') return 0;;
    'h') return 0;;
  esac
  return 1
}

check_not_friendly() {  # check black/white piece already occupies square
  local proposed_pos=$1
}

check_piece_moves() {  # is pawn, knight, queen, king...
  local piece_type=$1
  local piece_pos=$2
}

check_if_valid_move() {
  local move=$1
  local from="${move:0:2}"
  local to="${move:2:2}"
  local piece="*"
  if [[ $turn_r -eq 0 ]]; then
    piece=${light_pieces[$from]}
  else
    piece=${dark_pieces[$from]}
  fi
  check_valid_input "$move"
  check_within_board "$to"
  check_not_friendly "$to"
  check_piece_moves "$piece" "$to"
}

move_piece() {
  local move=$1
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
  print_all
  if [[ turn_r -eq 0 ]]; then
    tput cup 25 66       # move cursor to setup for input
    read -p "W > " move  # prompt for move, store in move var
    move_piece "$move"
    turn_r=$turn_r+1
    turn=$turn+1
  else
    tput cup 25 66
    read -p "B > " move
    move_piece "$move"
    turn_r=$turn_r-1
    turn=$turn+1
  fi
  clear
done
