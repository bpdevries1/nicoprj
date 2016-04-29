# GnuplotDepFile.rb

require "Depfile.rb"

class GnuplotDepFile < DepFile

	def handleLine(line)
		# puts @filename + ": GnuplotDepFile.handleline: do something"
		
		if line =~ /set output \'(.*)\'/
			fname = $1
			# puts "#{@filename} outputs #{fname}"
			addRef fname, "output"
		end
	end

	def depFileType
		"gnuplot.m"
	end

end