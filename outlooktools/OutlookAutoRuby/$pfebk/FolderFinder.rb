# FolderFinder - library class for finding Outlook folders

class FolderFinder
	def find(folderName)
		puts "finding: #{folderName}"
		return 123
	end

	# zoek folder 1 niveau diep
	def findFolder (parentFolder, folderName) 
		folders = parentFolder.Folders

		#class << folders
	#		include Enumerable
	#	end

		result = folders.find {|folder| folder.name == folderName}

		return result	  
	end

	def findFolderPath(ns, path)
	  # set folders [$ns : Folders]
	  f = ns
		lFolderNames = path.split("/")
		lFolderNames.each {
			|folderName|
			f = findFolder(f, folderName)
	  }
		return f
	end

end

