# DepFileFactory - Factory for instantiating DepFile objects and descendents.

require "DepFile.rb"
require "AhkDepFile.rb"
require "TclDepFile.rb"
require "BatDepFile.rb"
require "AntDepFile.rb"
require "GnuplotDepFile.rb"
require "WikiDepFile.rb"
require "FileDepFile.rb"

class DepFileFactory

	def DepFileFactory::new(basedir, fullpath, hashOptions = Hash.new)
		dir = fullpath
		# remove basedir from fullpath in reldir
		# first check if the basedir appears in fullpath
		dir[basedir + "/"] = '' if dir[basedir + "/"]
		reldir, filename = File.split(dir)
       
		klass =
    	case filename.downcase
      	when /\.ahk$/
        	AhkDepFile
      	when /\.tcl$/
        	TclDepFile
        when /\.bat$/
          BatDepFile
        when /^build.*\.xml$/
          AntDepFile
        when /\.m$/
          GnuplotDepFile
        when /\.wiki$/
          WikiDepFile
        when /\.file$/
          FileDepFile
        else
          DepFile
      end
    # puts "Making object of type #{klass} for #{filename}" 
    klass::new(basedir, reldir, filename, hashOptions)
  end
end
