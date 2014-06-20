# DepFileList - list (array) of DepFile's
# doel: extra methoden voor zoeken DepFile's. Veel methods direct door-linken naar @lstDepFiles.

require 'singleton'

class DepFileList
	# singleton pattern
	include Singleton
	
	# # lstDepFiles niet definieren, want dan meteen ook reader en/of writer, en wil ik niet.
	attr_reader :lstDepFiles

	def initialize
		@lstDepFiles = Array.new
	end
	
	def push(depFile)
		@lstDepFiles.push depFile
	end

	# geef zowel alle parameters (*args) als de codeblock (&action) door aan array.each.
	def each(*args, &action)
		@lstDepFiles.each(*args, &action)
	end

	# filename is just the filename, no path info
	def findFiles(filename)
		@lstDepFiles.find_all {|depFile|  depFile.filename == filename }
	end

	# determine all the root-parents for a depFile.
	# a parent is a root_parent if it doesn't itself have parents.
	def get_root_parents(depFile)
		# puts "get_root_parents for: #{depFile}"
		result = Array.new
		get_root_parents_rec(depFile, result, [])
		return result	
	end

	def get_root_parents_rec(depFile, lst_parents, travel_path)
		# puts "get_root_parents_rec for: #{depFile}"
		return if travel_path.include?(depFile)
		travel_path.push(depFile)

		has_parents = false
		depFile.refs.each {
			|ref|
			if depFile == ref.sink
				get_root_parents_rec(ref.source, lst_parents, travel_path)
				has_parents = true
			end
		}
		if !has_parents
			if !lst_parents.include?(depFile)
				lst_parents.push(depFile)
			end
		end

		travel_path.pop

	end

end
