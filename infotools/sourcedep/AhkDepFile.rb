# AhkDepFile.rb

require "DepFile.rb"

class AhkDepFile < DepFile

	def handleLine(line)
		# puts @filename + ": AhkDepFile.handleline: do nothing"
		if line =~ /^;/
			# regel begint met ;, dus commentaar, dus niets.
		elsif line =~ /#Include %A_ScriptDir%\\(.+)/ 
			fname = $1
			# puts "#{@filename} sources #{fname}"
			# laatste teken van filename is mogelijk een newline, met chomp verwijderen.
			addRef fname.chomp, "include"
		end
	end

	def depFileType
		"Ahk"
	end

end
