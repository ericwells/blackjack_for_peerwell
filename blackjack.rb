# blackjack_peerwell.rb: a single-player version of blackjack which includes cheats for PeerWells experts ;)
# v14:  Nothing left to do! Completed on Oct 27 2016. Renaming to get rid of the v14 now.

# This program follows the Blackjack rules per Bicycle Playing Cards: www.bicyclecards.com/how-to-play/blackjack/.

# ENHANCEMENT:  Change the class structure so that not as many variables have to get passed back and forth in the method calls. Unclear what the best way to do that is.  Probably give Hand a pointer to the Player that owns it, or move lots of the action methods over to Player class.

# TO ANYONE READING THIS PROGRAM:  Here is the basic structure.  First the new classes are created along with their associated instance variables and methods.  Then the regular methods are created.  Then a bunch of stuff for the game is initialized.  Then there is a flow control block. Then end.

# NOTE TO SELF: Remember that for this version it really only makes sense to have one player (ie it is not intended to be an online multi-player game)

require 'fileutils'

class Hand # this class is necessary in order to allow for splitting pairs

	def initialize name_of_hand, array_of_cards, player_name
		@hand_number = name_of_hand
		@players_cards=array_of_cards
		@ace_flag = false # indicator if an Ace is in the player's hand
		@players_running_total = Array.new(2,0) # this array can only have two slots, one for the value with Ace low (also holds the value if no Ace in the hand) and one for the value with Ace high
		@bet = 0
		@player_name = player_name
		@is_doubled = false
	end

	def hand_number
		@hand_number
	end

	def players_cards
		@players_cards
	end

	def bet
		@bet
	end

	def ace_flag
		@ace_flag
	end

	def is_doubled
		@is_doubled
	end

	def reset_ace_flag
		@ace_flag = false
	end

	def reset_running_total
		@players_running_total = [0,0]
	end

	def reset_doubled
		@is_doubled = false
	end

	def players_running_total
		if !@ace_flag
			@players_running_total[0]
		elsif @players_running_total[1]<=21
			@players_running_total[1]
		else
			@players_running_total[0]
		end
	end

	def take_bet player, min_bet
		puts "What is #{@player_name}'s bet for your #{@hand_number} current hand? (enter integers from #{min_bet}-500)"
		@bet = gets.chomp.to_i
		while @bet > player.money || @bet < min_bet
			puts "You tried to place a bet that is bigger than the chip value you have available ($#{player.money}) or smaller than the minimum bet ($#{min_bet}).  Please enter a new value."
			@bet = gets.chomp.to_i
		end
		player.subtract_money(@bet)
		puts "Your bet is $#{@bet} for your #{@hand_number} current hand, and your pile of chips is at $#{player.money}"
	end

	def deal where_are_we_in_the_deck, the_shuffled_deck, pip_values, is_dealer
		@players_cards = [ the_shuffled_deck[where_are_we_in_the_deck], the_shuffled_deck[where_are_we_in_the_deck+1] ]
		####  OVERRIDE FOR BUG TESTING
		 # @players_cards = [ "Ace of Diamonds", "Jack of Diamonds" ] if !is_dealer  ### bug testing for naturals
		 # @players_cards = [ "Ace of Diamonds", "Jack of Diamonds" ] if is_dealer  ### bug testing for naturals
		 # @players_cards = [ "Ace of Diamonds", "Ace of Diamonds" ] if !is_dealer  ### bug testing for splitting Aces
		 # @players_cards = [ "Two of Diamonds", "Two of Diamonds" ] if !is_dealer  ### bug testing for splitting Twos
		 # @players_cards[0] = "Ace of Diamonds" if is_dealer  ### bug testing for insurance

		array_of_pip_values_for_player = @players_cards.map { |x| pip_values[x].to_i } # NOTE: this array is local to this function
		@players_running_total[0] = array_of_pip_values_for_player.reduce(0, :+).to_i # calculate players score
		@ace_flag = true if @players_cards.any?{|x| x=~/Ace(.*)/} 
		@players_running_total[1] = @players_running_total[0] + 10 if @ace_flag # use +10 as a simple way to adjust for Ace high
		self.say_the_dealt_cards(is_dealer)
	end

	def say_the_dealt_cards is_dealer
		if is_dealer
			puts "#{@player_name}'s cards are #{@players_cards[0]} and a mystery card"
		else 
			puts "#{@player_name}'s cards are #{@players_cards[0]} and #{@players_cards[1]}"
			@ace_flag ? puts("Player is showing a soft #{@players_running_total[1]}") : puts("#{@player_name} is showing #{@players_running_total[0]}")
		end
	end

	def hit where_are_we_in_the_deck, the_shuffled_deck, pip_values
		puts "#{@player_name} hits."
		@players_cards.push(the_shuffled_deck[where_are_we_in_the_deck])
		puts "#{@player_name}'s cards are: " + players_cards.join(", ") + "."
		array_of_pip_values_for_player = @players_cards.map { |x| pip_values[x].to_i } # OPTIMIZE:  too much of this is repeated from method=deal.  
		@players_running_total[0] = array_of_pip_values_for_player.reduce(0, :+).to_i 
		@ace_flag = true if @players_cards.any?{|x| x=~/Ace(.*)/}
		@players_running_total[1] = @players_running_total[0] + 10 if @ace_flag 
		(@ace_flag && @players_running_total[1]<=21) ? puts("#{@player_name} is showing a soft #{@players_running_total[1]}") : puts("#{@player_name} is showing #{@players_running_total[0]}")
	end

	def bust
		@players_running_total[0]>21 # at first is seems odd to ignore players_running_total[1], but think about it and you will realize it to be true
	end

	def win (player)
		player.add_money(@bet*2)
		puts "#{@player_name} wins and collects $#{@bet*2}.  Total chip value is now $#{player.money}."
	end

	def win_natural (player)
		player.add_money((@bet*2.5).to_i)
		puts "#{@player_name} wins and gets paid extra for the natural, therefore collects $#{(@bet*2.5).to_i}.  Total chip value is now $#{player.money}."
	end

	def lose (player)
		puts "#{@player_name} lost and loses current bet of $#{@bet}.  Total chip value is now $#{player.money}."
	end

	def tie (player)
		player.add_money(@bet)
		puts "#{@player_name} tied the dealer and takes the bet back. Total chip value is now $#{player.money}."
	end

	def rename
		@hand_number = "left"
	end

	def rename_back
		@hand_number = "only"
	end

	def pop_card_on_split
		@players_cards.pop
	end

	def seed_the_second_hand card
		@players_cards.push(card)
	end

	def add_cards_on_split where_are_we_in_the_deck, the_shuffled_deck, pip_values
		puts "Adding a card to the #{@hand_number} hand for #{@player_name}."
		@players_cards.push(the_shuffled_deck[where_are_we_in_the_deck])
		puts "#{@player_name}'s cards in the #{@hand_number} hand are: " + players_cards.join(", ") + "."
		array_of_pip_values_for_player = @players_cards.map { |x| pip_values[x].to_i } # OPTIMIZE:  too much of this is repeated from method=deal.  
		@players_running_total[0] = array_of_pip_values_for_player.reduce(0, :+).to_i 
		@ace_flag = true if @players_cards.any?{|x| x=~/Ace(.*)/}
		@players_running_total[1] = @players_running_total[0] + 10 if @ace_flag 
		(@ace_flag && @players_running_total[1]<=21) ? puts("#{@player_name} is showing a soft #{@players_running_total[1]} in #{@hand_number} hand.") : puts("#{@player_name} is showing #{@players_running_total[0]} in #{@hand_number} hand.")
	end

	def add_bet_on_split old_bet, the_entire_player_object
		puts "Since you split pairs, we'll need to add $#{old_bet} as the new bet on your right hand."
		the_entire_player_object.subtract_money(old_bet)
		@bet = old_bet
		puts "Your bet is $#{@bet} for your #{@hand_number} hand, and your pile of chips is at $#{the_entire_player_object.money}."
	end

	def settle is_dealer_bust, dealers_cards, the_entire_player_object
		if !self.bust && is_dealer_bust
			puts "Dealer was a bust"
			self.win(the_entire_player_object)
		elsif !self.bust && self.players_running_total>dealers_cards.players_running_total
			self.win(the_entire_player_object)
		elsif !self.bust && self.players_running_total<dealers_cards.players_running_total
			self.lose(the_entire_player_object)
		elsif !self.bust && self.players_running_total==dealers_cards.players_running_total
			self.tie(the_entire_player_object)
		end
	end

	def doubledown old_bet, the_entire_player_object, where_are_we_in_the_deck, the_shuffled_deck, pip_values
		puts "Since you are doubling down, we'll need to add $#{old_bet} to your bet."
		@bet += old_bet
		the_entire_player_object.subtract_money(old_bet)
		puts "Your bet is now at $#{@bet}, and your pile of chips is at $#{the_entire_player_object.money}."
		@is_doubled = true
		@players_cards.push(the_shuffled_deck[where_are_we_in_the_deck])
		array_of_pip_values_for_player = @players_cards.map { |x| pip_values[x].to_i } # OPTIMIZE:  too much of this is repeated from method=deal.  
		@players_running_total[0] = array_of_pip_values_for_player.reduce(0, :+).to_i 
		@ace_flag = true if @players_cards.any?{|x| x=~/Ace(.*)/}
		@players_running_total[1] = @players_running_total[0] + 10 if @ace_flag 
		puts "You now have one more face down card in your hand."
	end


end

class Player
	
	def initialize name
		@player_name = name
		@players_hands = Array.new
		@number_of_cheats = 2
		@money = 500
		self.create_first_hand
		@side_bet = 0
	end

	def create_first_hand
		@players_hands[0] = Hand.new("only", [] , @player_name)
	end
	
	def add_second_hand
		@players_hands[1] = Hand.new("right", [], @player_name)
		@players_hands[0].rename # rename the first hand from "only" to "left"
		@players_hands[1].seed_the_second_hand( @players_hands[0].pop_card_on_split )  # move the cards
	end

	def destroy_second_hand
		@players_hands.delete_at(1)
		@players_hands[0].rename_back # rename the first hand from "left" back to "only"
	end

	def money
		@money
	end

	def name
		@player_name
	end

	def players_hands
		@players_hands
	end

	def number_of_cheats
		@number_of_cheats
	end

	def subtract_money (amt)
		@money -= amt
	end

	def add_money (amt)
		@money += amt
	end

	def cheat dealer, questions, answers
		@number_of_cheats -= 1
		question_index = rand(0..questions.length-1)
		puts "The answers to all the cheat questions can be found somewhere on the www.PeerWell.co site."
		puts "#{questions[question_index]}"
		reply6 = gets.chomp.downcase
		if reply6 == answers[question_index]
			puts "Congrats, you got it correct.  The dealer's face down card is #{dealer.players_hands[0].players_cards[1]}. You have #{@number_of_cheats} cheats remaining."
		else
			puts "That is incorrect. You have #{@number_of_cheats} cheats remaining."
		end
	end

	def make_side_bet (amt)
		@side_bet = amt
	end

	def side_bet
		@side_bet
	end

	def reset_side_bet
		@side_bet = 0
	end

	def produce_summary (round)
		puts "Thank you for playing, #{@player_name}.  Your final cash value is $#{@money}. You played for #{round} rounds."
	end

end # end of Player class

def shuffle_the_deck the_deck
	the_shuffled_deck = the_deck.shuffle
	puts "The dealer has shuffled the deck."
end

def out_of_cards? where_are_we_in_the_deck
	where_are_we_in_the_deck > 45
end




## THIS IS THE START OF THE MAIN PROGRAM

# initialize stuff

# initialize peerwell_questions as dict
# alternatively the peerwell questions could be of form a,b,c,d questions plus a hint which takes you to the relevant source content

# read the deck from file.  Store the pip values in a hash table and also load the cards into an array.
pip_values = Hash.new
the_deck = Array.new
File.readlines("blackjack_deck.txt").each_with_index do |line, index|
	i = 0
	temp_array = Array.new
	line.split(",").each do |thing|
		temp_array[i] = thing.chomp
		i += 1
	end
	pip_values["#{temp_array[0]}"] = temp_array[1]
	the_deck[index] = temp_array[0]
end

# create the holder for the shuffled deck
the_shuffled_deck = Hash.new
the_shuffled_deck = the_deck.shuffle
where_are_we_in_the_deck = 0

# get the PeerWell questions into a dictionary
questions = Array.new
answers = Array.new
File.readlines("./PeerWellQuestionsAnswersKey.txt").each_with_index do |line,index|
	i = 0
	temp_array = Array.new
	line.split(",").each do |thing|
		temp_array[i] = thing.chomp
		i += 1
	end
	questions[index] = temp_array[0]
	answers[index] = temp_array[1]
end

# initialize the game
pool_of_dealers = ["Monica", "Jessie", "Sam", "Max"]
min_bet = 50
dealer = Player.new(pool_of_dealers[rand(0..pool_of_dealers.length-1)])
puts "Welcome to the blackjack table.  Your dealer tonight is #{dealer.name}."
puts "what is the player's name?"
reply1 = gets.chomp.to_s
player_one = Player.new(reply1)
puts "#{player_one.name} is in the game with $#{player_one.money} worth of chips."
round = 0
end_game = false

# start the next round
while end_game == false

	# does player still have money?
	if player_one.money == 0
		puts "Unfortunately you are out of money.  The game will now end."
		player_one.produce_summary(round)
		end_game = true
		break
	end

	round += 1
	puts "Beginning Round #{round}"

	# clear all the necessary counters.
	player_one.players_hands[0].reset_ace_flag
	dealer.players_hands[0].reset_ace_flag
	player_one.players_hands[0].reset_running_total
	dealer.players_hands[0].reset_running_total
	player_one.players_hands[0].reset_doubled
	player_one.reset_side_bet
	
	# Destroy the second hand if it is floating around.
	if player_one.players_hands.length == 2
		player_one.players_hands[1].reset_ace_flag
		player_one.players_hands[1].reset_running_total
		player_one.destroy_second_hand
	end

	# take bets and deal
	player_one.players_hands[0].take_bet(player_one, min_bet)
	the_shuffled_deck = the_deck.shuffle
	where_are_we_in_the_deck = 0
	dealer.players_hands[0].deal(where_are_we_in_the_deck, the_shuffled_deck, pip_values, true) # NOTE: in proper blackjack the cards should be dealt one at a time around the table, but that can easily be fixed later if required.
	where_are_we_in_the_deck += 2
	player_one.players_hands[0].deal(where_are_we_in_the_deck, the_shuffled_deck, pip_values, false)
	where_are_we_in_the_deck += 2

	# check for insurance
	if dealer.players_hands[0].players_cards[0].split[0] == "Ace"
		while true
			puts "The dealer's face-up card is an Ace.  Do you want to take insurance? (y/n)"
			reply4 = gets.chomp.downcase
			if reply4 != "n" && reply4 != "y"
				puts "Invalid input.  Try again."
			else
				break
			end
		end
		if reply4 == "y"
			while true
				puts "How much would you like to wager on the side bet? Must be between $0 and $#{((player_one.players_hands[0].bet)*0.5).to_i}."
				reply5 = gets.chomp.to_i
				if !( reply5.between?(0, (player_one.players_hands[0].bet)*0.5) )
					puts "Invalid input. Try again."
				elsif reply5 > player_one.money
					puts "You don't have enough remaining chips to cover a double down bet.  Try again."
				else
					break
				end
			end
			player_one.make_side_bet(reply5)
			puts "Dealer will now check the hole card."
			if pip_values[dealer.players_hands[0].players_cards[1]].to_i >= 10
				puts "Hole card was a ten-card. The card is #{dealer.players_hands[0].players_cards[1]}."
				player_one.add_money(player_one.side_bet)
				puts "#{player_one.name} wins the side bet and collects $#{(player_one.side_bet)*2}. Pile of chips is now at $#{player_one.money}."
			else 
				puts "Hole card was not a ten-card. All side bets are lost. Pile of chips is at $#{player_one.money}."
			end
		end
	end

	# evaluate for naturals
	if dealer.players_hands[0].players_running_total == 21
		puts "Dealer has a natural 21."
		if player_one.players_hands[0].players_running_total == 21
			player_one.players_hands[0].tie(player_one)
		else
			player_one.players_hands[0].lose(player_one)
		end
		puts "Ending round #{round}."
	elsif player_one.players_hands[0].players_running_total == 21
		puts "Player has a natural 21."
		if dealer.players_hands[0].players_running_total == 21
			puts "Dealer has a 21 too."
			player_one.players_hands[0].tie(player_one)
		else
			puts "Dealer does not have 21."
			player_one.players_hands[0].win_natural(player_one)
		end
	else
		
		# the player's play
		while true
			puts "Type: (s) for Stand, (h) for Hit, (d) for Double Down, (p) for Split Pair, (c) for Cheat"
			reply3 = gets.chomp.downcase
			if reply3 == "h" # Hit
				player_one.players_hands[0].hit(where_are_we_in_the_deck, the_shuffled_deck, pip_values)
				where_are_we_in_the_deck += 1
				if player_one.players_hands[0].bust # when a bust is detected, just end the round.  Their money has already been subtracted from their bank and there is need to show the dealer's cards either.
					puts "Player has busted."
					player_one.players_hands[0].lose(player_one)
					break
				end
			elsif reply3 == "d" # Double down
				if !([9,10,11].include?(player_one.players_hands[0].players_running_total))
					puts "You don't have a total card value of 9, 10, or 11 and so can't double down right now. Try again."
				elsif player_one.players_hands[0].bet > player_one.money
					puts "You don't have enough remaining chips to cover a double down bet.  Try again."
				else
					player_one.players_hands[0].doubledown(player_one.players_hands[0].bet, player_one, where_are_we_in_the_deck, the_shuffled_deck, pip_values)
					where_are_we_in_the_deck += 1
					break
				end
			elsif reply3 == "c" # Cheat
				if player_one.number_of_cheats == 0 
					puts "You are out of cheats. Try again."
				else
					player_one.cheat(dealer, questions, answers)
				end
			elsif reply3 == "p" # Split. NOTE: Some casinos will allow re-splitting, but this program sticks with Bicycle Cards rules for blackjack which only allow a single split.
				if !(player_one.players_hands[0].players_cards[0].split[0] == player_one.players_hands[0].players_cards[1].split[0])
					puts "You don't have a starting pair and so can't split right now. Try again."
				elsif player_one.players_hands[0].bet > player_one.money
					puts "You don't have enough remaining chips to cover a second hand.  Try again."
				elsif player_one.players_hands[0].players_cards[0].split[0] == "Ace" && player_one.players_hands[0].players_cards[1].split[0] == "Ace"
					# spawn new hand, add one card to each, then tell them they can't add any more cards per the rules.  Note that if they get a ten card now, it pays regular and not at the increased natural 21 rate.
					player_one.add_second_hand
					player_one.players_hands[0].add_cards_on_split(where_are_we_in_the_deck, the_shuffled_deck, pip_values)
					where_are_we_in_the_deck += 1
					player_one.players_hands[1].add_cards_on_split(where_are_we_in_the_deck, the_shuffled_deck, pip_values)
					where_are_we_in_the_deck += 1
					puts "Since you had a pair of Aces on the split, you only get one card added to each hand and then your turn is over."
					break
				else
					# spawn a new hand
					player_one.add_second_hand
					player_one.players_hands[0].add_cards_on_split(where_are_we_in_the_deck, the_shuffled_deck, pip_values)
					where_are_we_in_the_deck += 1
					player_one.players_hands[1].add_cards_on_split(where_are_we_in_the_deck, the_shuffled_deck, pip_values)
					where_are_we_in_the_deck += 1
					puts "Continue playing out your left hand."
				end
			elsif reply3 == "s" # Stand
				puts "#{player_one.name} stands with #{player_one.players_hands[0].players_running_total} showing."
				break
			else
				puts "Invalid input. Try again."
			end
		end

		# if there is a second hand, then play that one out too (but with splitting further not allowed and doubling down not allowed.)(and unless they split a pair of Aces.)
		if player_one.players_hands[1] != nil
			player_one.players_hands[1].add_bet_on_split(player_one.players_hands[0].bet, player_one)			
		end
		if player_one.players_hands[1] != nil && !(player_one.players_hands[0].players_cards[0].split[0] == "Ace" && player_one.players_hands[1].players_cards[0].split[0] == "Ace")
			puts "Continue playing out your right hand. Your right hand is showing #{player_one.players_hands[1].players_running_total}."
			while true
				puts "Type: (s) for Stand, (h) for Hit, (c) for Cheat"
				reply3 = gets.chomp.downcase
				if reply3 == "h"
					player_one.players_hands[1].hit(where_are_we_in_the_deck, the_shuffled_deck, pip_values)
					where_are_we_in_the_deck += 1
					if player_one.players_hands[1].bust # when a bust is detected, just end the round.  Their money has already been subtracted from their bank and there is need to show the dealer's cards either.
						puts "Player has busted."
						player_one.players_hands[1].lose(player_one)
						break
					end
				elsif reply3 == "c"
					if player_one.number_of_cheats == 0 
						puts "You are out of cheats. Try again."
					else
						player_one.cheat(dealer)
					end
				elsif reply3 == "s"
					puts "#{player_one.name} stands with #{player_one.players_hands[1].players_running_total} showing."
					break
				else
					puts "Invalid input. Try again."
				end
			end	
		end

		if player_one.players_hands[1] != nil # If there are two hands...
			if !player_one.players_hands[0].bust || (player_one.players_hands[1] != nil && !player_one.players_hands[1].bust)  # Only play out the dealer's cards if at least one of the player's hands isn't a bust.
				# the dealer's play
				puts "Dealer's turn..."
				puts "#{dealer.name}'s face-down card was a #{dealer.players_hands[0].players_cards[1]}"
				dealer.players_hands[0].ace_flag ? puts("#{dealer.name} is showing a soft #{dealer.players_hands[0].players_running_total}") : puts("#{dealer.name} is showing #{dealer.players_hands[0].players_running_total}")
				while dealer.players_hands[0].players_running_total < 17 
					dealer.players_hands[0].hit(where_are_we_in_the_deck, the_shuffled_deck, pip_values)
					where_are_we_in_the_deck +=1 # OPTIMIZE: this could be improved by creating a Class of the_shuffled_deck
				end
			end
			# and settle...
			# if it wasn't a bust.
			if !player_one.players_hands[0].bust
				puts "Settle #{player_one.name}'s left hand."
				player_one.players_hands[0].settle(dealer.players_hands[0].bust, dealer.players_hands[0], player_one)
			end
			# if it wasn't a bust.
			if !player_one.players_hands[1].bust
				puts "Settle #{player_one.name}'s right hand."
				player_one.players_hands[1].settle(dealer.players_hands[0].bust, dealer.players_hands[0], player_one) 
			end
		else # If there is only one hand...
			if !player_one.players_hands[0].bust  # Only play out the dealer's cards if the player's hand isn't a bust.
				# the dealer's play
				puts "Dealer's turn..."
				puts "#{dealer.name}'s face-down card was a #{dealer.players_hands[0].players_cards[1]}"
				dealer.players_hands[0].ace_flag ? puts("#{dealer.name} is showing a soft #{dealer.players_hands[0].players_running_total}") : puts("#{dealer.name} is showing #{dealer.players_hands[0].players_running_total}")
				while dealer.players_hands[0].players_running_total < 17 
					dealer.players_hands[0].hit(where_are_we_in_the_deck, the_shuffled_deck, pip_values)
					where_are_we_in_the_deck +=1 # OPTIMIZE: this could be improved by creating a Class of the_shuffled_deck
				end
				# and settle...
				puts "Settle #{player_one.name}'s current hand."
				puts "The down card from the double down was a #{player_one.players_hands[0].players_cards[2]}." if player_one.players_hands[0].is_doubled
				player_one.players_hands[0].settle(dealer.players_hands[0].bust, dealer.players_hands[0], player_one)
			end
		end
	end # end for the if statement about dealer having a natural

	# does the player want to continue?  If yes, loop.  If no, print a summary.
	while true
		puts "Continue? (y/n)"
		reply2 = gets.chomp.downcase
		if reply2 != "n" && reply2 != "y"
			puts "Invalid input.  Try again."
		else
			break
		end
	end
	if reply2 == "n"
		player_one.produce_summary(round)
		break
	end
	puts "End of round #{round}"
	the_shuffled_deck = the_deck.shuffle

end # this is the while loop that keeps starting new rounds

puts "Game Over"