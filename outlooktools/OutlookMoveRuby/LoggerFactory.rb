# LoggerFactory
# 14-11-2009 problemen met lo4r, lijkt nu opgelost:
# met gem list --local lijst gezien, en hier staat log4r nu bij.
# in irb geprobeerd, werkte eerst niet, maar met eerst een require 'rubygems' werkt het daarna wel.
# outlookbatch deed het hierna ook weer.
# dus even onduidelijk wat er eerder deze week mis was.

require 'rubygems'
require 'singleton'

require 'log4r'
include Log4r

class LoggerFactory
	# singleton pattern
	include Singleton

	def get_logger(name)
		log = Logger.new name
		log.outputters = Outputter.stdout
		pf = PatternFormatter.new(:pattern => "%d [%-5l] [%c] %m")
		log.outputters.each {|outputter| outputter.formatter = pf}
		return log
	end

end
