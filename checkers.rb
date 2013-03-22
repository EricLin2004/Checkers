require 'colorize'
require 'debugger'
class Checkers
	
	def initialize
		@gameboard = Board.new
		@player1 = HumanPlayer.new(:red)
		@player2 = HumanPlayer.new(:white)
		@current_player = @player1
	end

	def run
		until @gameboard.over?
			debugger
			@gameboard.display
			@current_player.play_turn(@gameboard, prompt)
			@current_player = (@current_player == @player1) ? @player2 : @player1
		end

		@current_player = (@current_player == @player1) ? @player2 : @player1
		puts "#{@current_player.color} Player wins!"
	end

	def prompt
		"#{@current_player.color}".capitalize + " Player, what is your move? ex. a1, b2"
	end
end

class Board
	attr_reader :field

	def initialize
		make_board
	end

	def make_board
    @field = Array.new(8) { [''] * 8 }
    (0..7).each do |row|
    	(0..7).each do |col|
    		if (row+col)%2 == 1 && row < 3
    			@field[row][col] = Piece.new([row,col],:red)
    		elsif (row+col)%2 == 1 && row > 4
    			@field[row][col] = Piece.new([row,col],:white)
    		end
    	end
    end
  end

  def display
    print '  '
    'a'.upto('h') { |let| print " #{let} " }
    puts
    @field.each_with_index do |row, row_index|
      print "#{row_index} "
      row.each_with_index do |piece, col_index|
      	if (row_index + col_index)%2 == 1
	       if piece == ''
	         print '   '
	       else
	         print " #{piece.display_piece} "
	       end
	     else
	     	if piece == ''
	         print '   '.colorize(:background => :white)
	       else
	         print " #{piece.display_piece} ".colorize(:background => :white)
	       end
	     end
     end
     print " #{row_index}"
     puts
    end
    print '  '
    'a'.upto('h') { |let| print " #{let} " }
    puts
  end

	def over?
		piece_count[0] == 0 || piece_count[1] == 0
	end

	def piece_count
		red = 0
		white = 0
		(0..7).each do |row|
    	(0..7).each do |col|
    		if @field[row][col] == ''
    			next
    		elsif @field[row][col].color == :red
    			red += 1
    		elsif @field[row][col].color == :white
    			white += 1
    		end
    	end
    end
    [red, white]
	end

	def valid_move?(color, from_loc, to_loc)
		return false if object_at_loc(from_loc) == ''

		return false if object_at_loc(from_loc).color != color
	
		return false unless object_at_loc(to_loc) == ''

		return false unless in_bounds?(from_loc) && in_bounds?(to_loc)

		return true if possible_shift?(from_loc, to_loc)

		return false unless jump?(color, from_loc).include?(to_loc)	

		true
	end


	def possible_shift?(from_loc, to_loc)
		object_at_loc(from_loc).dxdy.each do |move|
			if from_loc[0] + move[0] == to_loc[0] && from_loc[1] + move[1] == to_loc[1]
				return true
			end
		end
		false
	end

	def jump?(color, from_loc)
		jump_pos = []
		mid_loc = ['','']
		final_loc = ['','']
		object_at_loc(from_loc).dxdy.each do |move|
			mid_loc[0], mid_loc[1] = (from_loc[0] + move[0]), (from_loc[1] + move[1])
			if in_bounds?(mid_loc)
				unless object_at_loc(mid_loc) == ''
					if object_at_loc(mid_loc).color != color
						final_loc[0], final_loc[1] = (from_loc[0] + 2*move[0]), (from_loc[1] + 2*move[1])
						if in_bounds?(final_loc)
							jump_pos << final_loc.dup
						end
					end
				end
			end
		end
		jump_pos
	end

	def object_at_loc(loc)
		@field[loc[0]][loc[1]]
	end

	def in_bounds?(from_loc)
		from_loc[0] < 8 && from_loc[1] < 8 && from_loc[0] >= 0 && from_loc[1] >= 0
	end

	def move_piece(from_loc, to_loc)
		if jump?(object_at_loc(from_loc).color, from_loc).include?(to_loc)
			mid_loc = ['','']
			tmp = ''
			object_at_loc(from_loc).dxdy.each do |move|
				mid_loc[0], mid_loc[1] = (from_loc[0] + move[0]), (from_loc[1] + move[1])
				if in_bounds?(mid_loc)
					unless object_at_loc(mid_loc) == ''
						if object_at_loc(mid_loc).color != object_at_loc(from_loc).color
							tmp = mid_loc.dup
							mid_loc[0], mid_loc[1] = (from_loc[0] + 2*move[0]), (from_loc[1] + 2*move[1])
							if mid_loc == to_loc
								@field[tmp[0]][tmp[1]] = ''
							end
						end
					end
				end
			end
		end

		if to_loc[0] == 0 || to_loc[0] == 7
			@field[to_loc[0]][to_loc[1]] = King.new(to_loc, object_at_loc(from_loc).color)
		else
			@field[to_loc[0]][to_loc[1]] = @field[from_loc[0]][from_loc[1]]
		end

		@field[from_loc[0]][from_loc[1]] = ''
		object_at_loc(to_loc).pos = to_loc
	end
end

class Piece
	attr_reader :color
	attr_accessor :pos, :sym

	def initialize(pos, color)
		@color = color
		@pos = pos
		@sym = 'O'
	end

	def display_piece
		@sym.colorize(@color)
	end

	def dxdy
		if @color == :red
			[[1,1],[1,-1]]
		else
			[[-1,1],[-1,-1]]
		end
	end
end

class King < Piece
	def initialize(pos, color)
		super(pos, color)
		@sym = 'K'
	end

	def dxdy
		[[1,1],[1,-1], [-1,-1],[-1,1]]
	end
end

class HumanPlayer
	attr_reader :color

	def initialize(color)
		@color = color
	end

	def play_turn(board, prompt)
		puts prompt
		diff = []
		from_loc, to_loc = get_loc

		until board.valid_move?(@color, from_loc, to_loc)
			puts "Invalid move. Try again ex. a1,b2"
			from_loc, to_loc = get_loc
		end

		diff[0] = to_loc[0].abs - from_loc[0].abs
		diff[1] = to_loc[1].abs - from_loc[1].abs
		if (diff[0].abs + diff[1].abs) == 2
			board.move_piece(from_loc, to_loc)
		else
			board.move_piece(from_loc, to_loc)
			unless object_at_jump?(board, @color, to_loc)
				puts prompt
				board.display
				play_turn(board, next_prompt)
			end
		end
	end

	def object_at_jump?(board, color, to_loc)
		jump = board.jump?(color, to_loc)
		return true if jump.empty?
		jump.each do |space|
			if board.object_at_loc(space) == ''
				return false
			end
		end
		true
	end

	def next_prompt
		"#{@color}".capitalize + " Player you must move again, choose your destination. ex. a1,b2"
	end

	def get_loc
		input = gets.chomp
		until input.split(',').length == 2
			puts "Invalid input, try format: a1, b2"
			input = gets.chomp
		end
		parse(input)
	end

	def parse(input)
		unless input.nil?
			move = input.split(',')
			from = [move[0][1].to_i, "abcdefgh".index(move[0][0])]
			to = [move[1][1].to_i, "abcdefgh".index(move[1][0])]
		end
		[from, to]
	end

end