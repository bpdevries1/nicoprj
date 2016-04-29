# DepFileFactory - Factory for instantiating DepFile objects and decendents.

require "DepFile.rb"
require "TclDepFile.rb"
require "BatDepFile.rb"
require "AntDepFile.rb"
require "GnuplotDepFile.rb"

class DepFileFactory

	def DepFileFactory::new(basedir, fullpath, hashOptions = Hash.new)
		dir = fullpath
		# remove basedir from fullpath in reldir
		# first check if the basedir appears in fullpath
		dir[basedir + "/"] = '' if dir[basedir + "/"]
		reldir, filename = File.split(dir)
       
		klass =
    	case filename.downcase
      	when /\.tcl$/
        	TclDepFile
        when /\.bat$/
          BatDepFile
        when /^build.*\.xml$/
          AntDepFile
        when /\.m$/
          GnuplotDepFile
        else
          DepFile
      end
    # puts "Making object of type #{klass} for #{filename}" 
    klass::new(basedir, reldir, filename, hashOptions)
  end
end
