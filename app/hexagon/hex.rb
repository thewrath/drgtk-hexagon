=begin
	Module "headless" for hexagonal map rendering.
	See : https://www.redblobgames.com/grids/hexagons/implementation.html
=end
Directions = [
	[1, 0], [1, -1], [0, -1], 
	[-1, 0], [-1, 1], [0, 1], 
]

class Hex
	attr_reader :q, :r, :s

	def initialize(q, r)
		@q = q
		@r = r
		@s = (-q - r)
	end

	# Utils
	def to_s
		"Hex q: #{@q}, r: #{@r}, s: #{@s}"
	end

	# Equality
	def ==(o)
		o.class == self.class && o.state == state
	end

	def !=(o)
		!(self == o)
	end

	# Coords arithmetic
	def add(o)
		Hex.new(@q + o.q, @r + o.r)
	end

	def sub(o)
		Hex.new(@q - o.q, @r - o.r)
	end

	def mul(o)
		Hex.new(@q * o.q, @r * o.r)
	end

	# Distance
	def len(o)
		(o.q.abs + o.r.abs + o.s.abs ) / 2
	end

	def dist(o)
		self.len(self.sub(o))
	end

	# Rotation
	def rotate_left()
		Hex.new(-@s, -@q)
	end

	def rotate_right()
		Hex.new(-@r, -@s)
	end

	#Scale
	def scale(s)
		Hex.new(@q * s, @r * s)
	end

	def direction(d)
		raise "Unknow  #{d} in 0-#{Directions.length}" unless d < Directions.length
		direction = Directions[d]
		Hex.new(direction[0], direction[1])
	end

	def neighbor(d)
		add(direction(d))
	end

	#Rounding
	def round()
		q = (@q).round
		r = (@r).round
		s = (@s).round

		q_diff = (q - @q).abs;
		r_diff = (r - @r).abs;
		s_diff = (s - @s).abs;

		if q_diff > r_diff && q_diff > s_diff
			q = -r - s
		elsif r_diff > s_diff
			r = -q - s
		else
			s = -q - r
		end

		Hex.new(q, r);
	end

	protected

	def state
		[@q, @r, @s]
	end

end

class HexType < Sprite
	attr_accessor :q, :r
	@@castle = 0
	@@tower = 1
	@@water = 2
	@@ground = 3

	def initialize(q, r, type)
		@q = q
		@r = r
		@s = (-q - r)
		@w = 64
		@h = 64
		@path = HexType.types[type]
	end

	def self.types
		["sprites/castle.png", "sprites/gate.png", "sprites/textureWater.png", "sprites/textureStone.png", "sprites/textureBricks.png", "sprites/chest.png", "sprites/fence.png", "sprites/treePines.png"]
	end

	# Get type of cell depending on the cell
	def self.getType(hex)
		distribution = Array.new(10, @@ground).concat(Array.new(3, @@water))

		if hex == Hex.new(0, 0)
			return @@castle
		else
			return distribution[get_random(0, distribution.length)]
		end
	end

end

class Orientation
	attr_reader :f0, :f1, :f2, :f3, :b0, :b1, :b2, :b3, :start_angle 

	def initialize(f0, f1, f2, f3, b0, b1, b2, b3, start_angle)
		@f0 = f0
		@f1 = f1
		@f2 = f2
		@f3 = f3
		@b0 = b0
		@b1 = b1
		@b2 = b2
		@b3 = b3
		@start_angle = start_angle
	end
end

# Pointy or Flat orientation
Pointy = Orientation.new(
	Math.sqrt(3.0),
	Math.sqrt(3.0) / 2.0,
	0.0,
	3.0 / 2.0,
	Math.sqrt(3.0) / 3.0,
	-1.0 / 3.0,
	0.0,
	2.0 / 3.0,
	0.5
)

Flat = Orientation.new(
	3.0 / 2.0,
	0.0,
	Math.sqrt(3.0) / 2.0,
	Math.sqrt(3.0),
	2.0 / 3.0,
	0.0,
	-1.0 / 3.0,
	Math.sqrt(3.0) / 3.0,
	0.0
)

class Point
	attr_accessor :x, :y

	def initialize(x, y)
		@x = x
		@y = y
	end

	def to_s
		"Point x: #{@x}, y: #{@y}"
	end
end

class Layout
	def initialize(orientation, size, origin)
		@orientation = orientation
		@size = size
		@origin = origin
	end

	def hex_to_pixel(h)
		x = (@orientation.f0 * h.q + @orientation.f1 * h.r) * @size.x
		y = (@orientation.f2 * h.q + @orientation.f3 * h.r) * @size.y
		
		Point.new(x + @origin.x, y + @origin.y)
	end

	def pixel_to_hex(p)
		pt = Point.new((p.x - @origin.x) / @size.x, (p.y - @origin.y) / @size.y)

		q = @orientation.b0 * pt.x + @orientation.b1 * pt.y
		r = @orientation.b2 * pt.x + @orientation.b3 * pt.y

		Hex.new(q, r)
	end

	def hex_corner_offset(c)
		angle = 2.0 * Math::PI * (@orientation.start_angle + c) / 6
		Point.new(@size.x * Math.cos(angle), @size.y * Math.sin(angle))
	end

	def polygon_corners(h)
		corners = []
		center = hex_to_pixel h
		(0..6).each do |c|
			offset = hex_corner_offset c
			corners << Point.new(center.x + offset.x, center.y + offset.y)
		end
		corners
	end
end

class HexMap
	attr_reader :layout, :hexes

	def initialize(layout, radius)
		@layout = layout
		@hexes = []
		@hexesType = []
		(-radius..radius).each do |q|
		    r1 = [-radius, -q - radius].max;
		    r2 = [radius, -q + radius].min;
		    (r1..r2).each do |r|
		      hex = Hex.new(q, r)
		      @hexes << hex
		      @hexesType << (HexType.new(q, r, HexType.getType(hex)))
		    end
  		end
	end

	def center()
		Hex.new(0, 0)
	end

	def ring(radius, start)
		results = []
	   	hex = start.add(start.direction(4).scale(radius))

	    (0..5).each do |i|
	    	(0..(radius-1)).each do |j|
	    		results << hex
	    		hex = hex.neighbor(i)
	    	end
	    end

    	return results
	end

	def remove_ring(ring)
		@hexes = @hexes.reject do |h|
			ring.include? h
		end

		@hexesType = @hexesType.select do |ht|
			@hexes.include? Hex.new(ht.q, ht.r)
		end
	end

	def update
		@hexes = @hexes.map do |h|
			yield(h)
		end
	end

	def render
		@hexes.each_with_index do |h, i| 
			corners = @layout.polygon_corners(h)
		    center = @layout.hex_to_pixel(h)

			yield(center, corners, h, @hexesType[i], i)
		end
	end
end
