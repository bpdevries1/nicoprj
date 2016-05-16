# AbstractTraveller

require "LoggerFactory.rb"

class AbstractTraveller
	attr_reader :name

	def initialize(elTraveller)
		@log = LoggerFactory.instance.get_logger "abstracttraveller"
		@name = elTraveller.attributes['name']
	  @outputters = Array.new
	end

	def add_outputter(outputter)
		@log.debug "Adding #{outputter.name} to #{@name}"
		@outputters << outputter
	end
	
	def prepare_all
		@outputters.each {|outputter| outputter.prepare_all}
	end

	def teardown_all
		@outputters.each {|outputter| outputter.teardown_all}
	end

	def log_ignore
	
	end

end
