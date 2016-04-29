# DotOutputter - make a .dot file (graph input) from a startfile

# not a singleton after all, want to use instance vars (ignorefiles)

require "AbstractOutputter.rb"
require "URLLocator.rb"

class DotOutputter < AbstractOutputter

	# attributes
	# attr_reader :travelledDepFiles, :ignoredDepFiles

	# @dotfile - output file.

	# def initialize(elOutput, travellers)
	def initialize(elOutput)
		super(elOutput)
		# @DOT_EXE = 'c:\util\ATT\graphviz\bin\dot.exe'
		# @DOT_EXE = 'C:\nico\util\graphviz186\bin\dot.exe'
		@DOT_EXE = 'C:\nico\util\ATT\Graphviz\bin\dot.exe'

		# @startfilenames = elOutput.elements.to_a("startfiles/startfile").collect{|el| el.text}
		# @ignorefilenames = elOutput.elements.to_a("ignorefiles/ignorefile").collect{|el| el.text}
		# @travelledDepFiles = Array.new
		# @ignoredDepFiles = Array.new
		getOptions(elOutput)

		# travellers.each{|t| puts "Traveller.name = #{t.name}"}

		#traveller_name = elOutput.attributes['traveller']
		#traveller = travellers.find {|traveller| traveller.name == traveller_name}
		#traveller.add_outputter(self)
		
		make_output_dirs
	end

	def getOptions(elOutput)
		@options = Hash.new
		@options['edgelabels'] = 'true'
		@options['edges_as_nodes'] = 'false'
		# @options['outputroot'] = '.'
		
		elOutput.elements.to_a("options/option").each{|elOption| getOption elOption}
		# puts "Options: value of edgelabels => #{@options['edgelabels']}"
	end

	def getOption(elOption)
		@options[elOption.attributes['name']] = elOption.attributes['value']
	end

	def make_output_dirs
		make_dir @outputroot
		make_dir @outputroot + "/png"
		make_dir @outputroot + "/tmp"
		make_dir @outputroot + "/sources"
		# make_dir @outputroot + "/deps"
	end

	def output_root_header(depFile)
		@fnameDot = get_dotfilename depFile
		@dotFile = File.open(@fnameDot, "w")
		@dotFile.puts "digraph G {"
		@dotFile.puts "  rankdir = \"LR\""
		# 12 inch breed, past dan net niet in de breedte op 15" scherm.
		@dotFile.puts "  size = \"12,50\""
		
		@edgecounter = 0
	end

	def get_dotfilename depFile
		return @outputroot + '/tmp/' + depFile.filename + ".dot"
	end

	def output_root_footer(depFile)
		@dotFile.puts "}"
		@dotFile.close
		
		# @todo bit strange to do these things in the _footer method.
		# fnamePng = get_pngfilename depFile
		fnamePng = URLLocator.instance.get_image_loc depFile
		
		# fnameMap = get_mapfilename depFile
		fnameMap = URLLocator.instance.get_map_loc depFile
		
		system(@DOT_EXE, '-Tpng', '-o', fnamePng, @fnameDot)
		system(@DOT_EXE, '-Tcmap', '-o', fnameMap, @fnameDot)
	end

	def output_node(depFile)
		if depFile.exists
			style = "solid"
			# url = "file:///" + depFile.fullpath
			url = URLLocator.instance.get_deps_url depFile
		else
		  style = "dashed"
		  url = ""
		end	
		# style = (depFile.exists ? "solid" : "dashed")
		
		@dotFile.puts "  #{toDotNodeName(depFile.filename)} " + 
			"[label=\"#{depFile.filename}\", style=#{style}, URL=\"#{url}\"];"
	end

	def output_noderef(ref)
		if (@options['edges_as_nodes'] == 'true')
			@edgecounter += 1
			edgenodename = "_edge#{@edgecounter}" 
			src = toDotNodeName(ref.source.filename)
			sink = toDotNodeName(ref.sink.filename)
	
			@dotFile.puts "  #{edgenodename} [label=\"#{ref.dep_params.toDotLabel}\", fontsize=8, color=white, height = .1, fixedsize=false, shape=box];"
			@dotFile.puts "  #{src} -> #{edgenodename} [dir=none];"
			@dotFile.puts "  #{edgenodename} -> #{sink};"
		else
			if (@options['edgelabels'] == 'true')
				edgelabel = ref.dep_params.toDotLabel
			else
				edgelabel = ""			
			end
			@dotFile.puts "  #{toDotNodeName(ref.source.filename)} -> #{toDotNodeName(ref.sink.filename)} " + 
				"[label=\"#{edgelabel}\", fontsize=8];"
		end
	end

	def toDotNodeName(filename)
		result = String.new(filename)
		# result.gsub!(/[-\.\$\{\}\@]/, '_')
		# beter: alles vervangen dat geen letter, cijfer of _ is.
		result.gsub!(/\W/, '_')
		
		# als het met een cijfer begint (4), dan probleem...
		return "_" + result
	end

end
