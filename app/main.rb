=begin
  Todo :
    - Manage resources using hexagon map
    - Design of card
    - Add sound on card interaction
=end

require 'app/utils.rb'
require 'app/hexagon/hex.rb'
require 'app/turn.rb'
require 'app/card.rb'
require 'app/resource.rb'

MapRadius = 3
HexSize = 42

# Program entry point
def tick args
  # State init
  init(args)

  # Print FPS
  args.state.debug_labels << "FPS : #{args.gtk.current_framerate.round}"
  args.state.debug_labels << "Frame : #{args.state.tick_count}"
  args.state.debug_labels << "Turn : #{args.state.game.current_turn.number}"
  # args.state.debug_labels << "Mouse : (#{args.inputs.mouse.x}, #{args.inputs.mouse.y})"
  # args.state.debug_labels << "Hex : (#{args.state.hovered_hex.q}, #{args.state.hovered_hex.r})"
  # args.state.debug_labels << "Ring size : #{args.state.ring_size}"

  draw_debug_labels args

  # Compute mouse position in hex space
  args.state.hovered_hex = (args.state.map.layout.pixel_to_hex(Point.new(args.inputs.mouse.x, args.inputs.mouse.y))).round

  # Draw hex map
  if !args.state.render_target.valid then
    compute_hex_map_render_targets args  
  end

  # Draw hex map render targets
  args.outputs.sprites << { x: 0, y: 0, w: args.grid.right, h: args.grid.top, path: :hex_map}
  args.outputs.sprites << { x: 0, y: 0, w: args.grid.right, h: args.grid.top, path: :hex_map_sprites}
  args.outputs.sprites << { x: 0, y: 0, w: args.grid.right, h: args.grid.top, path: :hex_map_ring}

  # Update player deck
  args.state.deck.tick(args) {|hand, c| on_card_used(hand, c, args)}

  # Do game update
  args.state.turn_manager.tick args

  # Draw resources
  args.state.store.tick args

  # Do delayed jobs
  do_delayed_jobs args
end

def draw_debug_labels args
  args.state.debug_labels.reverse.each_with_index do |l, i|
    args.outputs.debug << [50, args.grid.top - (50 + (30*i)), l, 255, 0, 0].labels
  end

  args.state.debug_labels = []
end

def compute_hex_map_render_targets args
  # This function use render target.

  args.state.map.render do |center, corners, hex, hexType, hi|
    # Color depending if hexes is in ring or not
    hexColor = {r: 0, g: 0, b: 0}

    last_corner = Point.new(0, 0)
    # Draw each side
    corners.each_with_index do |c, ci|
      args.render_target(:hex_map).lines  << {x: last_corner.x, y: last_corner.y, x2: c.x, y2: c.y, r: hexColor.r, g: hexColor.g, b: hexColor.b, a: 255} unless ci == 0 
      last_corner = c
    end

    # Draw center of hex
    if args.state.ring_hexes.include? hex
      size = HexSize/4
      args.render_target(:hex_map_ring).sprites << { x: center.x-(size/2), y: center.y-(size/2), w: args.grid.right, h: args.grid.top, path: :ring_marker}      
    end

    # Draw sprite representing case type on top of hex
    hexType.x = center.x-(hexType.w/2)
    hexType.y = center.y-(hexType.h/2)

    args.render_target(:hex_map_sprites).sprites << hexType

    # Uncomment here to get hex position 
    # args.outputs.debug << [center.x-10, center.y+15, "x:#{hex.q}", -4, 0, 0, 0, 0].labels
    # args.outputs.debug << [center.x-10, center.y, "y:#{hex.r}", -4, 0, 0, 0, 0].labels
  end

  args.state.render_target.valid = true
end

def next_ring args
  (args.state.ring_size += 1)
  args.state.ring_size = 1 if args.state.ring_size > MapRadius

  start = args.state.map.center
  args.state.ring_hexes = args.state.map.ring(args.state.ring_size, start)
  args.state.render_target.valid = false
end

def on_turn_start(turn, args)
  puts "Turn start"
  args.state.deck.next_hand
  args.state.ring_size = 0 # Put ring size to zero is enought to recompute new hexes ring
end

def on_turn_end(turn, args)
  puts "Turn stop #{args.state.tick_count}"
  args.state.deck.clear_hand
end

def on_card_used(hand, card, args)
  # Compute next ring when card is used
  next_ring args

  # Pass turn if player use all card allowed for one turn
  # -1 is required because last used card isn't destroyed yet
  if (hand.length - 1 <= Deck.hand_size - Turn.card_per_turn)
    args.state.turn_manager.pass_turn
  end
end

def init args
  args.outputs.background_color = [255, 255, 255]

  args.state.debug_labels ||= []

  args.state.map ||= HexMap.new(Layout.new(Flat, Point.new(HexSize, HexSize), Point.new(args.grid.right/2, args.grid.top/2 + 75)), MapRadius)

  # Setup render targets used by hexMap for performances
  args.state.render_target.valid ||= false

  # Ring
  args.state.ring_size ||= 0
  args.state.ring_hexes ||= []
  args.render_target(:ring_marker).solids << {x: 0, y: 0, w: HexSize / 4, h: HexSize / 4, r: 255, g: 0, b: 0}

  next_ring args if args.state.ring_size == 0

  # Game turn
  args.state.turn_manager ||= TurnManager.new(lambda {|t| on_turn_start(t, args) }, lambda {|t| on_turn_end(t, args)} )

  # Player deck
  args.state.deck ||= Deck.new({x: args.grid.right - 200, y: 50}, {x: args.grid.right/4, y: 50})

  # Player resources
  args.state.store ||= Store.new(Store.initial_resources)

  # Start first turn (the game)
  args.state.turn_manager.start
end