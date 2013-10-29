require 'win32ole'
require "./FolderFinder.rb"
require "./EmailFolders.rb"
require "./FolderChooser.rb"
require "./LoggerFactory.rb"

# alle OLE objecten hebben blijkbaar dezelfde class: WIN32OLE. Hier Enumerable aan
# toevoegen, zodat bv find beschikbaar komt.
class WIN32OLE
	include Enumerable
end

class Main
  
  def initialize
 		@log = LoggerFactory.instance.get_logger "Main"
		@log.level=INFO
  end
  
  def run
		# puts "Outlook show number of items in TODO folders"
		myApp = WIN32OLE::new("outlook.Application")
		WIN32OLE.const_load(myApp, OutlookConst)

		ns = myApp.GetNameSpace("MAPI")
		#ns.Logon # uncomment for online usage
		@ff = FolderFinder.new
		@ff.set_namespace(ns)
		puts "Todo folders with items:"
		show_foldername_items "Inbox"
		show_foldername_items "Wacht"
		show_foldername_items "Parkeerplaats"
		show_foldername_items "Afhandelen"
		show_foldername_items "TODO"
		
		puts "Todo folders with #items:"
		show_foldername "Inbox"
		show_foldername "Wacht"
		show_foldername "Parkeerplaats"
		show_foldername "Afhandelen"
		show_foldername "TODO"
  end

  def show_foldername name 
		lst_todo = @ff.search_folders(name) # list of MailFolder
		# lst_todo.each {|fld| puts "#{fld.outlook_folder.items.count} -  #{fld.path}" if fld.outlook_folder.items.count > 0}
		lst_todo.each {|fld| puts "#{'%3d' % fld.outlook_folder.items.count} -  #{fld.path}" if fld.outlook_folder.items.count > 0}
  end
  
  def show_foldername_items name 
		lst_todo = @ff.search_folders(name) # list of MailFolder
		lst_todo.each {|fld| 
		  if fld.outlook_folder.items.count > 0
        puts "#{'%3d' % fld.outlook_folder.items.count} -  #{fld.path}" 
        puts "-"*20
        fld.outlook_folder.items.each {|msg|
          puts "#{msg.SentOn}/#{msg.SenderName}/#{msg.Subject}"
        }
        puts "="*40
      end
		}
  end
  
end

class OutlookConst
end

main = Main.new
main.run

