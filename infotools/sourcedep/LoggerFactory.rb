# LoggerFactory

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
