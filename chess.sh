#!/bin/bash

# Setup, dependencies
bgLight="\033[48;5;235m"
reset="\033[0m"
turn_r=0  # global variable that flips every time the turn is handed off

declare -A board

for row in {0..7}; do
  for col in {0..7}; do
    board[$col,$row]=""
  done
done

board[0,7]="♖"; board[1,7]="♘"; board[2,7]="♗"; board[3,7]="♕"; board[4,7]="♔"; board[5,7]="♗"; board[6,7]="♘"; board[7,7]="♖";
board[0,6]="♙"; board[1,6]="♙"; board[2,6]="♙"; board[3,6]="♙"; board[4,6]="♙"; board[5,6]="♙"; board[6,6]="♙"; board[7,6]="♙";
board[0,1]="♟"; board[1,1]="♟"; board[2,1]="♟"; board[3,1]="♟"; board[4,1]="♟"; board[5,1]="♟"; board[6,1]="♟"; board[7,1]="♟";
board[0,0]="♜"; board[1,0]="♞"; board[2,0]="♝"; board[3,0]="♛"; board[4,0]="♚"; board[5,0]="♝"; board[6,0]="♞"; board[7,0]="♜";

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
    file=$(($(printf '%d' "'$file") - 97))  # a rather elegant solution I found online to convert file to numbers 0-7 (using their ascii codes)
  fi
  rank=$((rank-1))
  echo "$file $rank"
}

turn_remainder() {  # returns the turn remainder with %. (e.g. 13%2=1, 54%2=0) I don't think I'll need this but it's here if I do
  local turn=$1
  turn_r=$((turn%2))
  echo "$turn_r"
}

print_char() {  # actually prints the piece given the turn, unicode char, and position (currently in <letter><number> will probably change)
  local piece_type=$1
  local file=$2
  local rank=$3
  # where we print the pieces depending on orientation of board.
  if [[ $turn_r -eq 0 ]]; then
    tput cup "$((25-3*rank))" "$((7*file+10))" 
  else
    tput cup "$((4+3*rank))" "$((59-7*file))"
  fi
  # print the piece with respective background
  if [[ $(((rank+file)%2)) -eq 0 ]]; then  # checking if it's on light or dark square
    echo -e "${reset}$piece_type"
  else
    echo -e "${bgLight}$piece_type"
  fi
  tput sgr0
}

print_all() {
  local error=$1
  tput sgr0
  draw_board
  print_coords
  for row in {0..7}; do
    for col in {0..7}; do
      local piece="${board[$col,$row]}"
      if [[ -n "$piece" ]]; then  # only print if there's a piece on that square
        print_char "$piece" "$col" "$row"
      fi
    done
  done
  tput cup 27 66
  echo "$error"
}



# Main logic
check_valid_input() {  # checks for correct length
  local move=$1
  if [[ ${#move} -ne 4 ]]; then
    return 1
  fi
  return 0
}

check_within_board() {  # make sure within board
  local proposed_file=$1
  local proposed_rank=$2
  if [[ "$proposed_file" -lt 0 || "$proposed_file" -gt 7 || "$proposed_rank" -lt 0 || "$proposed_rank" -gt 7 ]]; then
    return 1
  fi
  return 0
}

check_not_friendly() {  # check black/white piece already occupies square
  local proposed_file=$1
  local proposed_rank=$2
  local piece="${board[$proposed_file,$proposed_rank]}"  # we could just pass the piece at proposed location, but I think this is cleaner and more contained
  if [[ "$turn_r" -eq 0 ]]; then
    case $piece in
      "♟"|"♞"|"♝"|"♜"|"♛"|"♚")  # if the turn is wihte and the proposed move already equals one of these pieces, fail
        return 1 ;;
    esac
  else
    case $piece in
      "♙"|"♘"|"♗"|"♖"|"♕"|"♔")  # if turn is black and proposed square has a black piece, we know it's friendly
        return 1 ;;
    esac
  fi
  return 0
}

check_moving_self() {
  local from=$1
  converted_coords=$(convert_UCI_to_coords "$from")
  local file rank; read file rank <<< "$converted_coords"
  local piece="${board[$file,$rank]}"
  if [[ "$turn_r" -eq 0 ]]; then  # if white's turn, make sure the space we're moving from is a white piece
    case $piece in
      "♟"|"♞"|"♝"|"♜"|"♛"|"♚")
        return 0 ;;
    esac
  else
    case $piece in
      "♙"|"♘"|"♗"|"♖"|"♕"|"♔")
        return 0 ;;
    esac
  fi
  return 1
}


check_piece_moves() {  # is pawn, knight, queen, king...
  local piece_type=$1
  local xfile=$2
  local xrank=$3
  local proposed_file=$4
  local proposed_rank=$5

  local file_diff=$((proposed_file-xfile))
  local rank_diff=$((proposed_rank-xrank))
  local abs_file_diff=${file_diff#-}  # most pieces move symmetrically, so these values can help us abstract a lot
  local abs_rank_diff=${rank_diff#-}

  # WE DON'T NEED TO IMPORT TURN. WE JUST NEED TO CHECK IF THERE'S ANY PIECE BETWEEN FROM AND TO
  case $piece_type in
    "♟")
      if [[ $xrank -eq 1 && $rank_diff -lt 3 && ${board[$proposed_file,$proposed_rank]} == "" && ${board[$proposed_file,$((proposed_rank-1))]} == "" ]]; then
        return 0  # first move, two squares ahead are empty
      elif [[ $rank_diff -eq 1 && ${board[$proposed_file,$proposed_rank]} == "" ]]; then
        return 0  # moving forward one, space ahead is empty
      elif [[ $rank_diff -eq 1 && $abs_file_diff -eq 1 && ${board[$proposed_file,$proposed_rank]} != "" ]]; then
        return 0  # can move diagonally if piece to capture. We've already checked at this point if friendly or not
      fi
      return 1
      ;;
    "♜"|"♖")
      if [[ $abs_file_diff -gt 0 && $abs_rank_diff -eq 0 ]]; then  # moving horizontally
        if [[ $file_diff -gt 0 ]]; then  # moving right
          for (( i=1; i<abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile+i)),$xrank]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $file_diff -lt 0 ]]; then  # moving left
          for (( i=1; i< abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile-i)),$xrank]}" ]]; then
              return 1  # piece in the way
            fi
          done
        fi
      elif [[ $abs_file_diff -eq 0 && $abs_rank_diff -gt 0 ]]; then  # moving vertically
        if [[ $rank_diff -gt 0 ]]; then  # moving forward (white, works for black, but black would be moving "backwards" in this case)
          for (( i=1; i<abs_rank_diff; i++ )); do
            if [[ -n "${board[$xfile,$((xrank+i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $rank_diff -lt 0 ]]; then  # moving backward
          for (( i=1; i<abs_rank_diff; i++ )); do
            if [[ -n "${board[$xfile,$((xrank-i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        fi
      else
        return 1  # moving at some diagonal
      fi
      return 0  # passed all checks
      ;;
    "♞"|"♘") 
      if [[ ($abs_file_diff -eq 2 && $abs_rank_diff -eq 1) || ($abs_file_diff -eq 1 && $abs_rank_diff -eq 2) ]]; then
        return 0
      fi
      return 1
      ;;
    "♝"|"♗")
      if [[ $abs_file_diff -eq $abs_rank_diff ]]; then
        if [[ $file_diff -gt 0 && $rank_diff -gt 0 ]]; then  # moving top-right
          for (( i=1; i<abs_file_diff; i++ )); do  # we can use abs_file_diff to parse all four scenarios because it is the same as abs_rank_diff (at this point)
            if [[ -n "${board[$((xfile+i)),$((xrank+i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $file_diff -gt 0 && $rank_diff -lt 0 ]]; then  # moving bottom-right
          for (( i=1; i<abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile+i)),$((xrank-i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $file_diff -lt 0 && $rank_diff -lt 0 ]]; then  # moving bottom-left
          for (( i=1; i<abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile-i)),$((xrank-i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $file_diff -lt 0 && $rank_diff -gt 0 ]]; then  # moving top-left
          for (( i=1; i<abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile-i)),$((xrank+i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        else
          return 1  # just in case
        fi
      else
        return 1  # rank and file differences not the same
      fi
      return 0  # passed all checks
      ;;
    "♛"|"♕")  # . _ .
      if [[ $abs_file_diff -gt 0 && $abs_rank_diff -eq 0 ]]; then  # moving horizontally
        if [[ $file_diff -gt 0 ]]; then  # moving right
          for (( i=1; i<abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile+i)),$xrank]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $file_diff -lt 0 ]]; then  # moving left
          for (( i=1; i< abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile-i)),$xrank]}" ]]; then
              return 1  # piece in the way
            fi
          done
        fi
      elif [[ $abs_file_diff -eq 0 && $abs_rank_diff -gt 0 ]]; then  # moving vertically
        if [[ $rank_diff -gt 0 ]]; then  # moving forward (white, works for black, but black would be moving "backwards" in this case)
          for (( i=1; i<abs_rank_diff; i++ )); do
            if [[ -n "${board[$xfile,$((xrank+i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $rank_diff -lt 0 ]]; then  # moving backward
          for (( i=1; i<abs_rank_diff; i++ )); do
            if [[ -n "${board[$xfile,$((xrank-i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        fi
      elif [[ $abs_file_diff -eq $abs_rank_diff ]]; then  # moving diagonally
        if [[ $file_diff -gt 0 && $rank_diff -gt 0 ]]; then  # moving top-right
          for (( i=1; i<abs_file_diff; i++ )); do  # we can use abs_file_diff to parse all four scenarios because it is the same as abs_rank_diff (at this point)
            if [[ -n "${board[$((xfile+i)),$((xrank+i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $file_diff -gt 0 && $rank_diff -lt 0 ]]; then  # moving bottom-right
          for (( i=1; i<abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile+i)),$((xrank-i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $file_diff -lt 0 && $rank_diff -lt 0 ]]; then  # moving bottom-left
          for (( i=1; i<abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile-i)),$((xrank-i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        elif [[ $file_diff -lt 0 && $rank_diff -gt 0 ]]; then  # moving top-left
          for (( i=1; i<abs_file_diff; i++ )); do
            if [[ -n "${board[$((xfile-i)),$((xrank+i))]}" ]]; then
              return 1  # piece in the way
            fi
          done
        else
          return 1  # just in case
        fi
      else
        return 1  # is some other illegal move
      fi
      return 0  # passed all checks
      ;;
    "♚"|"♔")
      if [[ $abs_file_diff -lt 2 && $abs_rank_diff -lt 2 ]]; then
        return 0
      fi
      return 1
      ;;
    "♙")
      if [[ $xrank -eq 6 && $rank_diff -gt -3 && ${board[$proposed_file,$proposed_rank]} == "" && ${board[$proposed_file,$((proposed_rank+1))]} == "" ]]; then
        return 0  # first move, two squares ahead are empty
      elif [[ $rank_diff -eq -1 && ${board[$proposed_file,$proposed_rank]} == "" ]]; then
        return 0  # moving forward one, space ahead is empty
      elif [[ $rank_diff -eq -1 && $abs_file_diff -eq 1 && ${board[$proposed_file,$proposed_rank]} != "" ]]; then
        return 0  # can move diagonally if piece to capture. We've already checked at this point if friendly or not
      fi
      return 1
      ;;
    *) 
      return 1  # just in case. Idk
      ;;
  esac
}


check_check() {  # checks if king is in check after proposed move
  local piece_type=$1
  local to=$2
  # will need to check for turn
  true
}


check_if_legal_move() {
  local move=$1  # in UCI
  local from="${move:0:2}"  # moving from in UCI
  local to="${move:2:2}"  # moving to in UCI

  converted_from=$(convert_UCI_to_coords "${move:0:2}")
  local xfile xrank; read xfile xrank <<< "$converted_from"  # file and rank in <num><num> (0-7)
  converted_to=$(convert_UCI_to_coords "$to")
  local file rank; read file rank <<< "$converted_to"  # file and rank in <num><num> (0-7)
  local piece="${board[$xfile,$xrank]}"

  if ! check_valid_input "$move"; then
    echo "Invalid input"
    return 1
  fi

  if ! check_within_board "$file" "$rank"; then
    echo "no  . _ ."
    return 1
  fi

  if ! check_not_friendly "$file" "$rank"; then
    echo "Cannot capture self"
    return 1
  fi

  if ! check_moving_self "$from"; then
    echo "Move a piece"
    return 1
  fi

  if ! check_piece_moves "$piece" "$xfile" "$xrank" "$file" "$rank"; then
    echo "Invalid move"
    return 1
  fi

  if ! check_check "$piece" "$to"; then
    echo "Check"
    return 1
  fi

  return 0
}

move_piece() {  # just move the piece assuming all legality checks have been done
  local move=$1

  converted_from=$(convert_UCI_to_coords "${move:0:2}")
  local xfile xrank; read xfile xrank <<< "$converted_from"  # file and rank in <num><num> (0-7)
  converted_to=$(convert_UCI_to_coords "${move:2:2}")
  local file rank; read file rank <<< "$converted_to"  # file and rank in <num><num> (0-7)

  local piece="${board[$xfile,$xrank]}"  # save piece that we'll move
  board[$xfile,$xrank]=""  # empty it's old location
  board[$file,$rank]="$piece"  # give new location the piece type
}
# setting up terminal to clear and hide cursor
tput smcup
tput civis
clear
# upon exit, run these
trap 'tput cnorm; tput rmcup; exit 0' INT TERM EXIT

while true; do
  print_all "$error"
  if [[ turn_r -eq 0 ]]; then
    tput cup 25 66       # move cursor to setup for input
    read -p "W > " move  # prompt for move, store in move var
    if check_if_legal_move "$move"; then
      move_piece "$move"
      turn_r=$((turn_r+1))
      turn=$((turn+1))
      error=""
    else
      error=$(check_if_legal_move "$move")
    fi
  else
    tput cup 25 66
    read -p "B > " move
    if check_if_legal_move "$move"; then
      move_piece "$move"
      turn_r=$((turn_r-1))
      turn=$((turn+1))
      error=""
    else
      error=$(check_if_legal_move "$move")
    fi
  fi
  clear
done
