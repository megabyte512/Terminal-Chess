#!/bin/bash

# Setup, dependencies
bgLight="\033[48;5;235m"
reset="\033[0m"


draw_board() {
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

print_coords() {
  local turn=$1
  tput sgr0
  if [[ $turn -eq 0 ]]; then
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

print_piece() {
  local turn=$1
  local piece_type=$2
  local piece_pos=$3
  local temp_file=${piece_pos:0:1}
  local rank=${piece_pos:1:1}
  if [[ "$temp_file" =~ [a-h] ]]; then
    file=$(($(printf '%d' "'$temp_file") - 96))  # a rather elegant solution I found online to convert file to numbers 1-8 (using their ascii codes)
  fi
  # where we print the pieces depending on orientation of board.
  if [[ $turn -eq 0 ]]; then
    tput cup "$((28-3*rank))" "$((7*file+3))" 
  else
    tput cup "$((1+3*rank))" "$((66-7*file))"
  fi
  # print the piece with respective background
  if [[ $(((rank+file)%2)) -eq 0 ]]; then
    echo -e "${reset}$piece_type"
  else
    echo -e "${bgLight}$piece_type"
  fi
}
# Main logic

# setting up terminal to clear and hide cursor
tput smcup
tput civis
clear
# upon exit, run these
trap 'tput cnorm; tput rmcup; exit 0' INT TERM EXIT

draw_board
print_coords 0
print_piece 0 ♔ e1
print_piece 0 ♕ d1
print_piece 0 ♖ a1
print_piece 0 ♖ h1
print_piece 0 ♗ c1
print_piece 0 ♗ f1
print_piece 0 ♘ b1
print_piece 0 ♘ g1
print_piece 0 ♙ a2
print_piece 0 ♙ b2
print_piece 0 ♙ c2
print_piece 0 ♙ d2
print_piece 0 ♙ e2
print_piece 0 ♙ f2
print_piece 0 ♙ g2
print_piece 0 ♙ h2

print_piece 0 ♚ e8
print_piece 0 ♛ d8
print_piece 0 ♜ a8
print_piece 0 ♜ h8
print_piece 0 ♝ c8
print_piece 0 ♝ f8
print_piece 0 ♞ b8
print_piece 0 ♞ g8
print_piece 0 ♟ a7
print_piece 0 ♟ b7
print_piece 0 ♟ c7
print_piece 0 ♟ d7
print_piece 0 ♟ e7
print_piece 0 ♟ f7
print_piece 0 ♟ g7
print_piece 0 ♟ h7

while true; do
  true
done
