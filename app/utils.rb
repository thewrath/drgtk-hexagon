# Dragon Ruby class to draw stuff
class Sprite
  attr_accessor :x, :y, :w, :h, :path, :angle, :a, :r, :g, :b,
                :source_x, :source_y, :source_w, :source_h,
                :tile_x, :tile_y, :tile_w, :tile_h,
                :flip_horizontally, :flip_vertically,
                :angle_anchor_x, :angle_anchor_y, :blendmode_enum

  def primitive_marker
    :sprite
  end
end

class Solid
  attr_accessor :x, :y, :w, :h, :r, :g, :b, :a, :blendmode_enum

  def primitive_marker
    :solid
  end
end

def get_random a, b
  rand(b-1) + a
end

# Register job that need to be done in futur frame
def delayed_job(args, number_of_frame, job)
  args.state.delayed_jobs ||= []
  args.state.delayed_jobs << { frame: args.state.tick_count + number_of_frame, job: job, frequency: number_of_frame }
end

# Process all delayed jobs
def do_delayed_jobs args
  args.state.delayed_jobs ||= []
  args.state.delayed_jobs.reject! do |j|
    if j.frame.elapsed? then
      j.frame = args.state.tick_count + j.frequency
      # No need of explicit return here because of Ruby ...
      j.job.call(args)
    else
      return false
    end
  end
end