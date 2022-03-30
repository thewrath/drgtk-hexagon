# Class representing the game (responsible of swaping turn, compute score, ...)
class TurnManager
	attr_reader :current_turn

	def initialize(onTurnStart, onTurnEnd)
		@current_turn = Turn.new(1)
		@onTurnStart = onTurnStart
		@onTurnEnd = onTurnEnd

		@time = 0
		@started = false

		# Display
		@turn_start_label = {x: nil, y: nil, text: "Turn #{@current_turn.number} start !", show: true, duration: 120, r: 255, g: 0, b:0}
	end

	def start
		unless @started
			turn_start
			@started = true
		end 
	end

	def tick args
		@time += (1/args.gtk.current_framerate)
		# If time elasped start next turn
		if @time > @current_turn.duration
			pass_turn
		end

  		args.state.debug_labels << "Remaining time : #{(@current_turn.duration - @time).round}"
	  	args.state.debug_labels << "Turn : #{@current_turn.number}"

  		# Display turn start label
  		@turn_start_label.x ||= args.grid.right/2 - 50
  		@turn_start_label.y ||= args.grid.top - 20
  		if (@turn_start_label.show) then
			args.outputs.labels << @turn_start_label 
  			@turn_start_label.next_remove ||= args.state.tick_count + @turn_start_label.duration
  			if @turn_start_label.next_remove.elapsed? then
  				@turn_start_label.next_remove = nil
  				@turn_start_label.show = false
  			end
		end
	end

	def pass_turn
		turn_end
		@current_turn = get_next_turn
		@time = 0
		turn_start
	end

	private
	
	def turn_start
		@turn_start_label.show = true
		@turn_start_label.text = "Turn #{@current_turn.number} start !"
		@onTurnStart.call(@current_turn)
	end

	def turn_end
		@onTurnEnd.call(@current_turn)
	end

	# Create next turn
	def get_next_turn
		Turn.new(@current_turn.number + 1)
	end
end

# Class representing turn
class Turn
	@@card_per_turn = 3
	@@default_duration = 30

	def self.card_per_turn
		@@card_per_turn
	end

	attr_reader :number, :phase, :duration
		
	def initialize(n)
		@number = n

		# Maximum duration in second
		@duration = @@default_duration

		@phase = Phase.new()
	end
end

# Class representing turn phase (turn is composed of two different phase)
class Phase
end