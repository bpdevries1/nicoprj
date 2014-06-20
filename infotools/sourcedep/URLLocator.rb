# URLLocator - one place to define all the URL's in the project

require 'singleton'

require "DepFile.rb"

class URLLocator
	include Singleton

	attr_accessor :outputroot
	
	def get_source_url (dep_file)
		return "file:///" + dep_file.fullpath
	end

	def get_deps_url (dep_file)
		return "file:///" + get_deps_loc(dep_file)
	end

	def get_deps_loc (dep_file)
		return @outputroot + '/deps/' + dep_file.filename + ".html"
	end

	def get_image_url (dep_file)
		return "file:///" + get_image_loc(dep_file)
	end

	def get_image_loc (dep_file)
		return @outputroot + '/png/' + dep_file.filename + ".png"
	end

	def get_map_loc (dep_file)
		return @outputroot + '/tmp/' + dep_file.filename + ".map"
	end

	def get_deps_href (dep_file, showtype="filename")
		strshow = dep_file.filename if showtype == "filename"
		strshow = dep_file.relpath if showtype == "relpath"
		if dep_file.exists
			url = get_deps_url dep_file
			return "<a href=\"#{url}\">#{strshow}</a>"
		else
			return strshow		
		end
	end

end
