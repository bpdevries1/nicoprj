# DepFile.rb - Dependency File Entry.
# key = full path name.

require "DepFileRef.rb"
require "DepParams.rb"

class DepFile

	# geen slashes voor en na de attributen, wel in-between.
	# als reldir leeg is, wordt er door split een . in gezet, zodat koppelen met slashes (/) weer goed gaat.
	attr_accessor :basedir, :reldir, :filename

	# @refs is een lijst van en naar deze file.
	attr_reader :refs, :exists

  def initialize(basedir, reldir, filename, hashOptions)
		@basedir  = basedir
		@reldir   = reldir
		@filename = filename
		@refs = Array.new
		@exists = hashOptions["exists"]
  end

	# fullpath berekende waarde.
	def fullpath
		@basedir + "/" + @reldir + "/" + @filename
	end

	def relpath
		@reldir + "/" + @filename
	end

	def to_s
		fullpath
	end

	# operator for sorting.
	def <=>(other)
		fullpath <=> other.fullpath
	end

	def readFile
		# puts "@todo: readFile"
		if FileTest.exists?(fullpath)
			IO.foreach(fullpath) { 
				|line| 
				# puts @filename + ": " + line 
				handleLine line
			}
		end
	end

	def handleLine(line)
		# puts @filename + ": DepFile.handleline: do nothing"
	end

	# fname normally is a relative filename
	# default behaviour: strip the path info, look for the filename
	def addRef(relname, reftype, params=nil)
		reldir, filename = File.split(relname)
		depfiles = DepFileList.instance.findFiles(filename)

   	# if no files found, make a new file and add refs.
   	if depfiles.size == 0
   		depfile = DepFileFactory.new("<unknown>", relname)
			depfiles.push(depfile)
			DepFileList.instance.push(depfile)
   	end

   	depfiles.each {
   		|depfile| 
   		dfr = DepFileRef.new(self, depfile, reftype, DepParams.new(params))
   		# put the ref in the reflists of both DepFile objects
   		@refs.push(dfr)
   		depfile.refs.push(dfr)
   	}
	end

	def putsRefs
		puts "#{@filename} [#{depFileType}] refers to:"
			@refs.each {
				|ref|
				puts "  " + ref.to_s if self == ref.source
			}
		puts "#{@filename} is refered by:"
			@refs.each {
				|ref|
				puts "  " + ref.to_s if self == ref.sink
			}
		if refs.size == 0
			puts "*** #{fullpath} is all alone! ***"
		end
		puts "-----------------------------------"
	end

	def depFileType
		"<default>"
	end

end
