# TclDepFile.rb

require "DepFile.rb"

class TclDepFile < DepFile

	def handleLine(line)
		# puts @filename + ": TclDepFile.handleline: do nothing"
		if line =~ /^#/
			# regel begint met #, dus commentaar, dus niets.
		elsif line =~ /^source ([^$()]+)$/
			# std gebruik: source filename.tcl
			fname = $1
			# puts "#{@filename} sources #{fname}"
			# laatste teken van filename is mogelijk een newline, met chomp verwijderen.
			addRef fname.chomp, "source"
		elsif line =~ /^source .+ ([^ ]+)\]$/
			# gebruik van source [file join abc def.tcl]
			fname = $1
			# puts "#{@filename} sources #{fname}"
			addRef fname, "source"
		end
	end

	def depFileType
		"Tcl"
	end

end
