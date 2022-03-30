# Chaque cellule du jeu contient une partie des ressources.
# Les effets de cartes s'appliquent sur les cellules et donc sur les ressources.

class CardModel

	attr_accessor :card_effect

	def initialize(card_effect)
		@card_effect = card_effect
	end

	# Tiny card factory
	def self.create_card()
		card_effects = [
			CardEffectModel.new([:gold], [10], [0])
		]

		return CardModel.new(card_effects[get_random(0, card_effects.length)])
	end

end

class CardView
	@@card_width = 128
	@@card_height = 128

	def self.card_width
		@@card_width
	end

	def self.card_height
		@@card_height
	end

	attr_accessor :initial_position, :state, :model

	def initialize()
		@x = 0
		@y = 0
		@w = @@card_width
		@h = @@card_height
		@path = "sprites/card_empty.png"

		@state = :idle
		@drag_offset = {x: 0, y: 0}
		@initial_position = {x: @x, y: @y}
	end

	def tick args
		# Can be dragged by mouse
		handle_drag args
	end

	def to_sprite
		[@x, @y, @w, @h, @path]
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
		when :hovered
			@y = @initial_position.y + @h/4
		when :idle
			@x = @initial_position.x
			@y = @initial_position.y
		end
	end
end

class CardEffectModel
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

class DeckModel
	@@deck_size = 20
	@@hand_size = 4

	def self.deck_size
		@@deck_size
	end

	def self.hand_size
		@@hand_size
	end

	attr_accessor :whole, :hand

	def initialize()
		@whole = Array.new(@@deck_size, nil).map.with_index{|n, i| CardModel.create_card()} # Todo: create deck from data file (JSON)
		@whole.shuffle!
		@hand = []
	end

	def next_hand
		# Fixme : it seems like new card instances are create using slice
		@hand = @whole.slice!(0, @@hand_size)
	end

	def clear_hand
		@hand.each {|c| c.state = :destroy}
	end

end	

class DeckView

	def initialize(deck_position, hand_position, model)
		@deck_position = deck_position 
		@hand_position = hand_position
		@model = model
		@card_view = CardView.new()
		@redraw_deck = true
	end

	def tick args
		# Update and draw hand
		# @model.hand.each do |c| 
		# 	c.update args
		# 	if c.state == :apply then
		# 		c.card_effect.apply(args.state.store)
		# 		yield(@hand, c)
		# 		c.state = :destroy
		# 	end
		# end

		# Destroy card
		# @model.hand.reject!{ |c| c.state == :destroy}
	end

	def draw args
		draw_hand args
		draw_deck args
	end

	private

	def draw_hand args
		args.outputs.sprites << @model.hand.map_with_index do |c, i|
			@card_view.x = @hand_position.x + ((@card_view.w + @card_view.w/8) * i)
			@card_view.y = @hand_position.y
			@card_view.to_sprite
		end
	end
	
	def draw_deck args
		# Deck is re-draw only if it's size change (for performance purpose) 
		if @redraw_deck then
			last_card_x = 0 
			args.render_target(:deck_card_target).sprites << @model.whole.map.with_index do |c, i|
				@card_view.x = @card_view.x+(i*3)
				last_card_x = @card_view.x
				@card_view
			end

			text_w, text_h = args.gtk.calcstringbox("#{@model.whole.length}", 0, "font.ttf")
			args.render_target(:deck_label_target).labels << {x: last_card_x + (CardView.card_width/2 - text_w/2), y: @deck_position.y + (CardView.card_height/2 + text_h/2), text: @deck_model.whole.length}

			@redraw_deck = false
		end

		args.outputs.sprites << { x: 0, y: 0, w: args.grid.right, h: args.grid.top, path: :deck_card_target}
		args.outputs.sprites << { x: 0, y: 0, w: args.grid.right, h: args.grid.top, path: :deck_label_target}
	end
end