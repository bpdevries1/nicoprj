# TclDepFile.rb

require "DepFile.rb"

class FileDepFile < DepFile

	def handleLine(line)
		# puts @filename + ": TclDepFile.handleline: do nothing"
		if line =~ /^#/
			# regel begint met #, dus commentaar, dus niets.
		elsif line =~ /^uses (.+)$/
			fname = $1
			# puts "#{@filename} sources #{fname}"
			# laatste teken van filename is mogelijk een newline, met chomp verwijderen.
			addRef fname.chomp, "uses"
		end
	end

	def depFileType
		"File"
	end

end
