# TravellerFactory

require "StartdownTraveller.rb"
require "NoTraveller.rb"

class TravellerFactory

	def TravellerFactory::new(elTraveller)
		klass =
    	case elTraveller.attributes['type']
      	when "startdown"
        	StartdownTraveller
				when "no"
				  NoTraveller
        else
          nil
      end
    # puts "Making object of type #{klass} for #{filename}" 
    klass::new(elTraveller)
  end
  
end