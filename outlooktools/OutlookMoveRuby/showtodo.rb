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
		@log.level=INFO
  end
  
  def run
		puts "Outlook show number of items in TODO folders"
		myApp = WIN32OLE::new("outlook.Application")
		WIN32OLE.const_load(myApp, OutlookConst)

		ns = myApp.GetNameSpace("MAPI")
		#ns.Logon # uncomment for online usage
		@ff = FolderFinder.new
		@ff.set_namespace(ns)
		
		show_foldername "Inbox"
		show_foldername "Wacht"
		show_foldername "Parkeerplaats"
		show_foldername "Afhandelen"
		show_foldername "TODO"
  end

  def show_foldername name 
		lst_todo = @ff.search_folders(name) # list of MailFolder
		lst_todo.each {|fld| puts "#{fld.outlook_folder.items.count} -  #{fld.path}" if fld.outlook_folder.items.count > 0}
  end
  
end

class OutlookConst
end

main = Main.new
main.run

