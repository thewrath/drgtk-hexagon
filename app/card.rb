# Chaque cellule du jeu contient une partie des ressources.
# Les effets de cartes s'appliquent sur les cellules et donc sur les ressources.

class Card < Sprite
	@@card_width = 128
	@@card_height = 128

	def self.card_width
		@@card_width
	end

	def self.card_height
		@@card_height
	end

	attr_accessor :card_effect, :initial_position, :initial_angle, :state

	def initialize(card_effect, position) 
		@card_effect = card_effect
		@x = position.x
		@y = position.y
		@w = @@card_width
		@h = @@card_height
		@path = "sprites/card_empty.png"

		@state = :idle
		@drag_offset = {x: 0, y: 0}
		@initial_position = {x: @x, y: @y}
		@initial_angle = 0
	end

	def update args
		# Can be dragged by mouse
		handle_drag args
	end

	private

	def reset_drag
		@state = :idle
		@x = @initial_position.x
		@y = @initial_position.y
	end

	def handle_drag args
		mouse = args.inputs.mouse
		if mouse.inside_rect?(self) && !(@state == :dragged) then
			@state = :hovered
		elsif !mouse.inside_rect?(self) && @state == :hovered then
			@state = :idle
		end
		if mouse.click then
			if mouse.inside_rect?(self) && !(@state == :dragged) then
				@state = :dragged
				@drag_offset.x = mouse.point.x - @x 
				@drag_offset.y = mouse.point.y - @y
			elsif @state == :dragged
				# Todo : check if it's on top of hex map
				@state = :apply
			end
		end

		# Undrag using escape
		if args.inputs.keyboard.key_down.escape then
			reset_drag 
		end

		case @state
		when :dragged
			@x = mouse.point.x - @drag_offset.x
			@y = mouse.point.y - @drag_offset.y
			@angle = 0
		when :hovered
			@y = @initial_position.y + @h/4
			@angle = 0
		when :idle
			@x = @initial_position.x
			@y = @initial_position.y
			@angle = @initial_angle
		end

	end

	# Tiny card factory
	def self.create_card(position)
		card_effects = [
			CardEffect.new([:gold], [10], [0])
		]

		return Card.new(card_effects[get_random(0, card_effects.length)], position)
	end
end

class CardEffect
	attr_accessor :resource_types, :positive_effects, :negative_effects

	def initialize(resource_types, positive_effects, negative_effects)
		@resource_types = resource_types
		@positive_effects = positive_effects
		@negative_effects = negative_effects

		validate
	end

	def apply(store)
		store.apply(self)
	end

	private

	def validate
		 if (@resource_types.length > @positive_effects.length || @resource_types.length > @negative_effects.length) then
			throw "The effect is invalid, a positive effect and a negative effect must be declared for each declared resource."  
		 end
	end

end

class Deck
	@@deck_size = 20
	@@hand_size = 4

	def self.deck_size
		@@deck_size
	end

	def self.hand_size
		@@hand_size
	end

	def initialize(deck_position, hand_position)
		@deck_position = deck_position 
		@hand_position = hand_position 
		@whole = Array.new(@@deck_size, nil).map.with_index{|n, i| Card.create_card(@deck_position)} # Todo: create deck from data file (JSON)
		@whole.shuffle!
		@hand = []
	end

	def next_hand
		card_angle = 30
		angle_step = (card_angle * 2) / (@@hand_size - 1)
		# Fixme : it seems like new card instances are create using slice
		@hand = @whole.slice!(0, @@hand_size).each_with_index do |c, i|
			c.x = @hand_position.x + ((c.w + c.w/8) * i)
			c.y = @hand_position.y
			c.angle = card_angle
			card_angle -= angle_step  

			c.initial_position = {x: c.x, y: c.y}
			c.initial_angle = c.angle
		end
	end

	def clear_hand
		@hand.each {|c| c.state = :destroy}
	end

	def tick args
		# Update and draw hand
		@hand.each do |c| 
			c.update args
			if c.state == :apply then
				c.card_effect.apply(args.state.store)
				yield(@hand, c)
				c.state = :destroy
			end
		end
		args.outputs.sprites << @hand.map {|c| c}

		# Destroy card
		@hand.reject!{|c| c.state == :destroy}

		# Draw deck
		draw_deck args
	end

	private
	
	def draw_deck args
		# Todo store deck size and redraw if change
		if then
			last_card_x = 0 
			args.render_target(:deck_card_target).sprites << @whole.map.with_index do |c, i|
				last_card_x = c.x+(i*3)
				{x: c.x+(i*3), y: c.y, path: c.path, w: c.w, h: c.h}
			end

			text_w, text_h = args.gtk.calcstringbox("#{@whole.length}", 0, "font.ttf")
			args.args.render_target(:deck_label_target).labels << {x: last_card_x + (Card.card_width/2 - text_w/2), y: @deck_position.y + (Card.card_height/2 + text_h/2), text: @whole.length}
		end

  		args.outputs.sprites << { x: 0, y: 0, w: args.grid.right, h: args.grid.top, path: :deck_card_target}
  		args.outputs.sprites << { x: 0, y: 0, w: args.grid.right, h: args.grid.top, path: :deck_label_target}
	end
end