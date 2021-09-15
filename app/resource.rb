# Class to represents a type of resource
class Resource
	attr_accessor :name, :current_amount, :initial_amount, :min_amount, :max_amount

	def initialize(name, initial_amount, min_amount, max_amount)
		@name = name
		@current_amount = initial_amount
		@initial_amount = initial_amount
		@min_amount = min_amount
		@max_amount = max_amount
	end

	def render args
  		args.state.debug_labels << "#{@name} : #{@current_amount}/#{@max_amount}"
	end
end

# Handle player resource
class Store
	attr_accessor :resources

	def initialize(resources)
		@resources = resources
	end

	def tick args
		@resources.each {|k, r| r.render args}
	end

	def apply(effect)
		effect.validate
		effect.resource_types.each_with_index do |r, i| 
			throw "Store cannot handle this kind of effect, resource missing : #{r}" unless (@resources.key? r)

			# All check are done
			@resources[r].current_amount += effect.positive_effects[i]
			@resources[r].current_amount += effect.negative_effects[i]
		end
	end

	def self.initial_resources
		{
			gold: Resource.new('Gold', 100, 0, 1000),
			wood: Resource.new('Wood', 300, 0, 1000),
			units: Resource.new('Units', 10, 0, 10),
		}
	end
end