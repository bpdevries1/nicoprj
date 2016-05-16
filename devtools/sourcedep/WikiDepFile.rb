# GnuplotDepFile.rb

require "DepFile.rb"

class WikiDepFile < DepFile

	def handleLine(line)
		# puts @filename + ": GnuplotDepFile.handleline: do something"
		# @todo in theorie ook mogelijk dat er 2 links op 1 regel staan.
		while line =~ /\[\[([^\]]+)\]\]/
			fname = $1
			re_before = $`
			re_after = $'
			if fname =~ /image:/
				# puts "#{@filename} outputs #{fname}"
				# deze overslaan.
			elsif fname =~ /media:/
				# ook overslaan
			elsif fname =~ /^(.+)\|/
				# mogelijk page|title
				fname = $1
				# addRef fname, "link"
				addRef "#{fname}.wiki", "link"
			else
				addRef "#{fname}.wiki", "link"
			end
			line = "#{re_before} #{re_after}"
		end
	end

	def depFileType
		"mediawiki"
	end

end