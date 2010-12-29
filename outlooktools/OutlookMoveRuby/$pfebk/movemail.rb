require 'win32ole'
require "FolderFinder.rb"
require "EmailFolders.rb"
require "FolderChooser.rb"
require "LoggerFactory.rb"

# alle OLE objecten hebben blijkbaar dezelfde class: WIN32OLE. Hier Enumerable aan
# toevoegen, zodat bv find beschikbaar komt.
class WIN32OLE
	include Enumerable
end

class Main
  
  def initialize
 		@log = LoggerFactory.instance.get_logger "Main"
  end
  
  def run
		puts "Outlook Move Ruby"
		myApp = WIN32OLE::new("outlook.Application")
		WIN32OLE.const_load(myApp, OutlookConst)

		ns = myApp.GetNameSpace("MAPI")
		#ns.Logon # uncomment for online usage
		@ff = FolderFinder.new
		@ff.set_namespace(ns)
		
		@folder_chooser = FolderChooser.new
		
		@email_folders = EmailFolders.new("emailfolders.xml", @ff)

		handle_folder(ns, "Persoonlijke mappen/Postvak IN")
		handle_folder(ns, "Persoonlijke mappen/Verzonden items")

		handle_todo_folder(ns, "Persoonlijke mappen/Taken", "Personal/Taken/Afgeronde taken")

		@email_folders.close
  end

	def handle_folder(ns, folder_name)
		fl_source = @ff.find_folder_path(ns, folder_name)
		puts "Found folder, name = #{fl_source.name}"
		handle_items(fl_source)
	end

	def handle_items(fl_source)
		# make a copy first, the original each is too dynamic when items are moved/deleted.
		copy = fl_source.Items.collect {|el| el}
		total = copy.size
		index = 1
		copy.each {
			|msg| 
			choice = handle_item(msg, index, total)
			index += 1
			break if choice.action == "quit"
		}
	end

	def handle_item(msg, index, total)
		puts "-" * 78
		puts "Mail #{index}/#{total}:"
		puts "Date: #{msg.SentOn}"
		puts "From: #{msg.SenderName}"
		puts "To: #{msg.To}"
		puts "Cc: #{msg.Cc}" if msg.Cc != ""
		puts "Subject: #{msg.Subject}"
		# only print first 500 characters of Body.
		puts "#{msg.Body[0,500]}"
		puts "---"
		mf = @email_folders.find_auto_folder(msg)
		if mf != nil
			move_item(msg, mf)
			choice = FolderChoice.new("auto", mf)
		else
			# don't move automatically, choose from a list
			fl_to = @email_folders.find_folders(msg)
		
			choice = @folder_chooser.choose_folder("Choose a folder: ", fl_to)
			if (choice.action == "select")
				move_item(msg, choice.folder)
			elsif (choice.action == "none")
			  puts "Don't move, continue"
			elsif (choice.action == "delete")
				msg.Delete
			elsif (choice.action == "new")
				puts "Need further processing"
				mf = select_new_folder(msg)
				if (mf != nil)
					@email_folders.add_folder(msg, mf)
					move_item(msg, mf)
				end
			elsif (choice.action == "newauto")
				puts "Need further processing"
				mf = select_new_folder(msg)
				key = select_key(msg)
				if (mf != nil) && (key != nil)
					@email_folders.set_auto_folder(key, mf)
					move_item(msg, mf)
				end			
			elsif (choice.action == "quit")
				puts "Quitting"
			else
				puts "Unknown, continue"
			end

		end
		return choice
	end

	def select_new_folder(msg)
		found = false
		result = nil
		while !found
			puts "Part of folder name: "
			part = gets.chomp
			mail_folders = @ff.search_folders(part)
			choice = @folder_chooser.choose_folder("Choose a new folder: ", mail_folders)
			if choice.action == "select"
				puts "Folder chosen: #{choice.folder.path}"
				result = choice.folder
				found = true
			elsif choice.action == "new"
			  found = false ; # so we can choose again...
			else
				found = true 
			end
		end
		return result
	end

	def	select_key(msg)
		found = false
		result = nil
		keys = @email_folders.msg_get_keys(msg)
		while !found
			i = 1
			keys.each {
				|key|
				puts "#{i}. #{key}"
				i += 1
			}
			puts "---"
			puts "0 = nothing, >0 = select"
			choice = gets.chomp
			i_choice = choice.to_i
			if (i_choice > 0) && (i_choice <= keys.size)
				result = keys[i_choice - 1]
				found = true
			elsif (i_choice == 0)
				result = nil
				found = true
			end
		end
		return result
	end

	def move_item(msg, mail_folder_to)
		puts "Moving item: #{msg.Subject} => #{mail_folder_to.path}"
		msg.Move(mail_folder_to.outlook_folder)
	end

	def handle_todo_folder(ns, folder_name, to_folder_name)
		fl_source = @ff.find_folder_path(ns, folder_name)
		puts "Found todo folder, name = #{fl_source.name}"
		fl_target = @ff.find_folder_path(ns, to_folder_name)
		handle_todo_items(fl_source, fl_target)
	end

	def handle_todo_items(fl_source, fl_target)
		# make a copy first, the original each is too dynamic when items are moved/deleted.
		copy = fl_source.Items.collect {|el| el}
		total = copy.size
		index = 1
		copy.each {
			|task| 
			choice = handle_todo_item(task, index, total, fl_target)
			index += 1
		}
	end

	def handle_todo_item(task, index, total, fl_target)
		puts "-" * 78
		puts "Todo #{index}/#{total}:"
		puts "Subject: #{task.Subject}"
		# only print first 500 characters of Body.
		puts "#{task.Body[0,500]}"
		puts "---"
		# puts "Status: #{task.Status}"
		puts "%complete: #{task.PercentComplete}"

		if task.PercentComplete == 100
			puts "Moving task: #{task.Subject}"
			task.Move(fl_target)
		end
		move_item(task, fl_target) if task.PercentComplete == 100


	end

end

class OutlookConst
end

main = Main.new
main.run

