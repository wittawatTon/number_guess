#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Function to handle user input and game logic
play_game() {
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  echo "Guess the secret number between 1 and 1000:"
  NUMBER_OF_GUESSES=0

  while true; do
    read GUESS

    # Check if the input is an integer
    if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
    else
      NUMBER_OF_GUESSES=$(( NUMBER_OF_GUESSES + 1 ))
      if (( GUESS == SECRET_NUMBER )); then
        echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
        #     You guessed it in <number_of_guesses> tries. The secret number was <secret_number>. Nice job!
        break
      elif (( GUESS < SECRET_NUMBER )); then
        echo "It's higher than that, guess again:"
      else
        echo "It's lower than that, guess again:"
      fi
    fi
  done
}

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if the user exists in the database
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Returning user
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Play the game
play_game

# Update the user's information in the database
if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
  BEST_GAME=$NUMBER_OF_GUESSES
fi

UPDATE_RESULT=$($PSQL "UPDATE users SET games_played = games_played + 1, best_game = $BEST_GAME WHERE user_id = $USER_ID")
