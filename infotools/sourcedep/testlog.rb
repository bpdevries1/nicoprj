require 'log4r'

class Testlog

	include Log4r

  def run
		# create a logger named 'mylog' that logs to stdout
		mylog = Logger.new 'mylog'
		mylog.outputters = Outputter.stdout
		pf = PatternFormatter.new(:pattern => "%d [%-5l] [%c] %m")
		mylog.outputters.each {|outputter| outputter.formatter = pf}
		do_log(mylog)
  end

	# Now we can log.
	def do_log(log)
	  log.debug "This is a message with level DEBUG"
	  log.info "This is a message with level INFO"
	  log.warn "This is a message with level WARN"
	  log.error "This is a message with level ERROR"
	  log.fatal "This is a message with level FATAL"
	end


end

Testlog.new.run
