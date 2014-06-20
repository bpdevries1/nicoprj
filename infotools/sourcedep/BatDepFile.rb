# BatDepFile

require "Depfile.rb"

class BatDepFile < DepFile

	def handleLine(line)
		# puts @filename + ": BatDepFile.handleline: do nothing"
		
		case line
	  	when /^rem /
	  	  # ignore line when it starts with rem.
	  	when /tclsh ([^ ]+\.tcl) /
				addBatRef $1, "calltcl", $'
			when /([^ ]+\.exe) /
				addBatRef $1, "callexe", $'
			when /^call ([^ ]+\.bat) /
				addBatRef $1, "callbat", $'
	  end		
	end

	def addBatRef(fname, calltype, callparams)
		callparams.chomp!
		addRef fname, calltype, callparams
	end

	def depFileType
		"Batch"
	end

end