# ActionFactory

require "Action.rb"

class ActionFactory

	def ActionFactory::new(elAction, travellers, outputters)
		klass = Action
    # puts "Making object of type #{klass} for #{filename}" 
    klass::new(elAction, travellers, outputters)
  end
  
end
