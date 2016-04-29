# StartdownTraveller

require "AbstractTraveller.rb"
require "DepFileList.rb"
require "LoggerFactory.rb"

class StartdownTraveller < AbstractTraveller

	# attributes
	# Outputter[] @outputters
	# DepFile[] @travelledDepFiles
	# DepFile[] @ignoredDepFiles
	# String[] @startfilenames
	# String[] @ignorefilenames
	# String name
	
	# attr_reader :name, :travelledDepFiles, :ignoredDepFiles
	attr_reader :travelledDepFiles, :ignoredDepFiles

	def initialize(elTraveller)
		super(elTraveller)
		@log = LoggerFactory.instance.get_logger "sdtravel"
		@startfilenames = elTraveller.elements.to_a("startfiles/startfile").collect{|el| el.text}
		# @ignorefilenames = elTraveller.elements.to_a("ignorefiles/ignorefile").collect{|el| el.text}
		@ignore_regexps = elTraveller.elements.to_a("ignorefiles/ignorefile").collect{|el| Regexp.new(el.text)}
		# @name = elTraveller.attributes['name']
	  # @outputters = Array.new
	  
	  getOptions(elTraveller)
	  # puts "Made new traveller: #{@name}"
	end

	def getOptions(elTraveller)
		@options = Hash.new
		@options['one_ref_only'] = 'false' ; # max 1 ref (edge) between 2 nodes.
		
		elTraveller.elements.to_a("options/option").each{|elOption| getOption elOption}
	end

	def getOption(elOption)
		@options[elOption.attributes['name']] = elOption.attributes['value']
	end

	def log_ignore
		prepare_all
		@log.debug "List of files to ignore for #{@name}:"
		@ignore_dep_files.sort.each{|depfile| @log.debug "Ignore file: #{depfile.relpath}"}
		@log.debug "End of list of files to ignore:"
	end

	def prepare_all
		super
		@travelledDepFiles = Array.new
		@ignoredDepFiles = Array.new
		# @unhandledDepFiles = DepFileList.instance.lstDepFiles
		fill_ignore_dep_files
	end

	def fill_ignore_dep_files
		@ignore_dep_files = Array.new
		# return @fileset.find {|re| re.match(dep_file.filename)}
	  @ignore_regexps.each {|re|
	  	# | is used for set union.
	  	@ignore_dep_files = @ignore_dep_files | DepFileList.instance.lstDepFiles.find_all {|dep_file|
	  		re.match(dep_file.relpath)
	  	}
	  }
	end

	def teardown_all
		# @unhandledDepFiles = @unhandledDepFiles - @travelledDepFiles - @ignoredDepFiles
		unhandledDepFiles = DepFileList.instance.lstDepFiles - @travelledDepFiles - @ignore_dep_files
		@outputters.each {|outputter| outputter.output_unhandled_list unhandledDepFiles}
		super
	end

  def travel(dep_file)
		# travelled_refs is reset with each travel.
		@travelled_refs = Array.new
		# @startfilenames.each{|startfile| travel_startfile startfile}
		# travel_startfile startfile
		travel_root(dep_file)		
	end

  def travel_startfile(startfile)
  	depFiles = DepFileList.instance.findFiles(startfile)
  	depFiles.sort.each{|depFile| travel_root(depFile)}
	end

	# @todo counting the 'indentation' level may be handy.
	def travel_root (depFile)
		@outputters.each {|outputter| outputter.output_root_header depFile}
		travel_node(depFile, [])
		@outputters.each {|outputter| outputter.output_root_footer depFile}
	end

	# travelpath: which path has been travelled up until this node?
	# if this node is already in the path, stop travelling.
	def travel_node(depFile, travelPath)
		return if travelPath.include?(depFile)
		return if @ignore_dep_files.include?(depFile)
		
		# add depFile here, before recursive travelling, so we have a stop condition.
		@travelledDepFiles.push(depFile)
		travelPath.push(depFile)
		
		@outputters.each {|outputter| outputter.output_node depFile}

		# only traverse refs if this node is the source
		# @todo this is a design decision, better make it a parameter somewhere.
		depFile.refs.sort.each {
			|ref|
			if depFile == ref.source
				if @ignore_dep_files.include?(ref.sink)
				  @ignoredDepFiles.push(ref.sink)
				else
					go_on = false
					if @options['one_ref_only'] == 'true'
						if (!@travelled_refs.find {|ref2| ref2.equals_source_sink?(ref)})
							go_on = true
							@travelled_refs.push(ref)
						end
					else
						go_on = true
					end
					
					if go_on
						@outputters.each {|outputter| outputter.output_noderef ref}
						travel_node(ref.sink, travelPath)
					end
				end
			end
		}
		travelPath.pop
	end

end
