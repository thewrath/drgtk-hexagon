# ===============================================================
# Welcome to repl.rb
# ===============================================================
# You can experiement with code within this file. Code in this
# file is only executed when you save (and only excecuted ONCE).
# ===============================================================

# ===============================================================
# REMOVE the "x" from the word "xrepl" and save the file to RUN
# the code in between the do/end block delimiters.
# ===============================================================

# ===============================================================
# ADD the "x" to the word "repl" (make it xrepl) and save the
# file to IGNORE the code in between the do/end block delimiters.
# ===============================================================

# Remove the x from xrepl to run the code. Add the x back to ignore to code.

require 'app/hexagon/hex.rb'
require 'app/utils.rb'

xrepl do
  array = Array.new(10, 1).each_with_index.map{|x, i| i}
  puts array
  # Print the whole array [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  puts array.pop(5)
  # Only print 9 instead of [9, 8, 7, 6, 5]
  puts array[0, 4]
end

xrepl do
  hexA = Hex.new(0, 0)
  hexB = Hex.new(0, 0)
  hexC = Hex.new(1, 0)

  puts hexA
  puts hexB
  puts hexC

  # Equality
  puts "hexA equals hexB" if (hexA == hexB)
  puts "hexA not equals hexC" unless (hexA == hexC)
  puts "hexB not equals hexC" if (hexB != hexC)

  # Coords arithmetic
  puts "Add : #{hexA.add hexB}" if (hexA.add hexB) == Hex.new(0, 0)
  puts "Sub : #{hexA.sub hexC}" if (hexA.sub hexC) == Hex.new(-1, 0)
  puts "Mul : #{hexA.mul hexC}" if (hexA.mul hexC) == Hex.new(0, 0)

  # Distance
  puts "Len : #{hexA.len hexA}"
  puts "Distance A-B : #{hexA.dist hexB}"
  puts "Distance A-C : #{hexA.dist hexC}"

  # Orientation
  puts Pointy
  puts Flat

  # Corners
  layout = Layout.new(Flat, Point.new(16, 16), Point.new(0, 0))
  corners = layout.polygon_corners hexA

  # Utils
  (0..100).each do |n|
    puts get_random(1, 10)
  end
end
