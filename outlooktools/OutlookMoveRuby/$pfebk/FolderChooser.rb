# FolderChooser: choose a folder from a list or choose a different action

require 'win32ole'
require "EmailFolders.rb"
require "LoggerFactory.rb"

class FolderChooser

	# list_folders: array of MailFolder objects or nil
	# @return a FolderChoice, never nil.
	def choose_folder(prompt, list_folders)
		# result = nil
		if list_folders != nil
			i = 1
			list_folders.each {|mailfolder| 
				puts "#{i}. #{mailfolder.path}"
				i += 1
			}
		else
			puts "<No folders>" 
		end
		puts "---"
		puts "0 = nothing, d = delete, n = new, q = quit"
		puts prompt
		choice = gets.chomp
		i_choice = choice.to_i
		if (i_choice > 0) && (i_choice <= list_folders.size)
			result = FolderChoice.new("select", list_folders[i_choice - 1])
		elsif (choice == "0")
			result = FolderChoice.new("none", nil)
		elsif (choice == "n")
		  result = FolderChoice.new("new", nil)
		elsif (choice == "d")
		  result = FolderChoice.new("delete", nil)
		elsif (choice == "q")
		  result = FolderChoice.new("quit", nil)
		else
			# default value of "none", could also do "error"
			result = FolderChoice.new("none", nil)
		end
		return result
	end

end

# action is a string (for now), folder is a MailFolder object.
class FolderChoice
	attr_reader :action, :folder
	
	def initialize(action, folder)
		@action = action
		@folder = folder
	end

end
