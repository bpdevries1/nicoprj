# FolderFinder - library class for finding Outlook folders

require 'win32ole'
require "EmailFolders.rb"
require "LoggerFactory.rb"

class FolderFinder
	
	def initialize
 		@log = LoggerFactory.instance.get_logger "FolderFinder"
 		@log.level=INFO
 		#puts "---"
 		#puts "Init logger done, log = #{@log}"
 		#@log.info("Logger started")
 		#@log.level=DEBUG
 		@log.debug("Logger started")
	end
	
	def set_namespace(ns)
		@ns = ns
	end
	
	def find(path)
		#puts "finding: #{folderName}"
		#return 123
		return find_folder_path(@ns, path)
	end

	# @todo kan zijn dat path niet uniek is (soms >1 Postvak IN), dan keuze maken voor foutmelding
	# of lijst teruggeven.
	def find_folder_path(ns, path)
		@log.debug("Searching Folder: #{path} in ns: #{ns}") 

	  # set folders [$ns : Folders]
	  f = ns
		lFolderNames = path.split("/")
		lFolderNames.each {
			|folderName|
			f = find_folder(f, folderName)
	  }
		return f
	end

	# zoek folder 1 niveau diep
	# @todo handle when a folder doesn't exist (renamed, moved, deleted, etc)
	def find_folder (parent_folder, folder_name) 
		# possible that path starts with a /, then the first part is empty
		# @log.debug("Searching Folder: #{folder_name} in parent: #{parent_folder.name}") 
		@log.debug("Searching Folder: #{folder_name}") 
		
		return parent_folder if folder_name == ""
		return parent_folder if parent_folder == nil
		
		folders = parent_folder.Folders
		# folders.each {|folder| puts "Folder: #{folder.name}"}

		result = folders.find {|folder| folder.name == folder_name}
		@log.debug("Result of find_folder: #{result.name}") if result != nil
		return result	  
	end

	# search all folders in the namespace based on part of the name
	# return an array of all folders (MailFolder = path + outlook-object) where the leaf of the
	# path contains part.
	def search_folders(part)
		return search_folders_rec(@ns, part, "")
	end

	def search_folders_rec(folder, part, path)
		# search in this parent_folder
		result = Array.new

		# niet de Ordina folders langs.
		if folder != @ns
			name = folder.name
			return result if name =~ /penbare mappen/
			return result if name =~ /Problemen met synchronisatie/
		end

		if folder != @ns
			name = folder.name
			@log.debug("Searching Folder: #{name} in path: #{path}") 
			@log.debug("-> result of name[part]: #{name[part]}")
			# case insensitive search with 2 downcases.
			if (name.downcase[part.downcase])
				result << MailFolder.new(path, folder)
			end
		end
		
		subfolders = folder.Folders
		# result = subfolders.find_all {|subfolder| subfolder.name[part]} .collect{|subfolder| MailFolder.new(path + "/" + subfolder.name, subfolder)}
		
		# search in sub_folders
		subfolders.each {|subfolder| result = result + search_folders_rec(subfolder, part, path + "/" + subfolder.name)}
		
		return result
	end

end

