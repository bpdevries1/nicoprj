# sourcedep.rb - Main class for sourcedep project.

$: << File.expand_path(File.dirname(__FILE__))

require "rexml/document"
include REXML  # so that we don't have to prefix everything with REXML::...

require 'find'
require 'fileutils'
include FileUtils::Verbose

# require 'log4r'
# include Log4r

require "DepFileList.rb"
#require "DepFile.rb"
#require "DepFileRef.rb"
require "DepFileFactory.rb"
puts "Before require OutputterFactory.rb"
require "OutputterFactory.rb"
puts "After require OutputterFactory.rb"
require "TravellerFactory.rb"
require "ActionFactory.rb"
require "LoggerFactory.rb"

class Main

	# instance vars:
	# basedirs
	# startfilenames: used to make dot/png files.
	# ignorefiles: ignore in plotting (not before).
	# outputters: objects to create output (dot/png for example)
	# log: log4r logger.	

	def initialize
		@log = LoggerFactory.instance.get_logger "sourcedep"
	end
	
  def run
		# puts "Sourcedep start"
		@log.info "Sourcedep start"
		readProject
		@log.info "have read project, now getting files..."

		getFiles
		@log.info "got files, now reading files..."

		# testje
		@travellers.each {|trav| trav.log_ignore}

		readFiles
		# logProject

		# @log.info "read files, now putting refs..."
		# putsRefs
		# putsDots
		
		# @log.info "put refs, now handling travellers..."
		# handle_travellers

		@log.info "read files, now handling actions..."
		handle_actions
		
		@log.info "Sourcedep finished"
		# puts "Sourcedep finished"
  end

	def readProject
		projectFilename = ARGV[0]
		file = File.new(projectFilename)
		doc = Document.new file
		root = doc.root

		@basedirs = root.elements.to_a("basedirs/basedir").collect{|el| el.text}
		@travellers = root.elements.to_a("travellers/traveller").collect{|el| TravellerFactory.new(el)}
		# @outputters = root.elements.to_a("outputters/outputter").collect{|el| OutputterFactory.new(el, @travellers)}
		@outputters = root.elements.to_a("outputters/outputter").collect{|el| OutputterFactory.new(el)}
		@actions = root.elements.to_a("actions/action").collect{|el| ActionFactory.new(el, @travellers, @outputters)}
	end

	def getFiles
		@depfiles = DepFileList.instance
		@basedirs.each{|basedir| getDirectory basedir}
	end

	def getDirectory(basedir)
		# puts "getdir #{basedir}"
		# code below is copied (and adapted) from an example...
	  Find.find( basedir ) do |path|
      # fname = path.sub( from_dir, '' )
      fdir, base = File.split( path )
      if FileTest.directory? path
        Find.prune if base[0] == ?. or 
                    base =~ /^(?:$pfebk|bak|test|_archief|_archive)$/i
      elsif FileTest.file? path
        unless base =~ /(?:\.png|\.jpeg|\.pdf|\.gif|\.psd|~)$/
          # copy path, fname
          # @depfiles.push path
          @depfiles.push DepFileFactory.new(basedir, path, 'exists' => true)
        end
      end
    end
	end

	def readFiles
		@depfiles.each {|depfile| depfile.readFile}
	end

	def putsRefs_old
		@depfiles.each {|depfile| depfile.putsRefs}
	end

	def handle_travellers_old
		unhandledDepFiles = @depfiles.lstDepFiles
		@travellers.each {|traveller|
			# traveller.makeOutput
			traveller.travel
			unhandledDepFiles = unhandledDepFiles - traveller.travelledDepFiles - 
													traveller.ignoredDepFiles
		}
		puts "Unhandled files:"
		# unhandledDepFiles.each{|depfile| puts depfile.to_s}
		unhandledDepFiles.each{|depfile| puts_unhandled_depfile depfile}
	end

	def handle_actions
		@actions.each {|action|
			action.do_action
		}
	end

	def puts_unhandled_depfile_old depfile
		puts "---------------------------"
		puts depfile.to_s
		root_parents = @depfiles.get_root_parents(depfile)
		root_parents.each {|root| puts "  root: #{root.to_s}"}
	end

	def logProject_old
		@basedirs.each {|basedir| puts "Basedir: " + basedir}
		@startfilenames.each {|startfile| puts "Startfile: " + startfile}
		@depfiles.each {|file| puts "File: " + file.to_s}
		# @depfiles.each {|file| puts file}
	end

end

main = Main.new
main.run

