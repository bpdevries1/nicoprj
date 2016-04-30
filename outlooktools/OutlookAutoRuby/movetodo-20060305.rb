require 'win32ole'
require "FolderFinder.rb"

# alle OLE objecten hebben blijkbaar dezelfde class: WIN32OLE. Hier Enumerable aan
# toevoegen, zodat bv find beschikbaar komt.
class WIN32OLE
	include Enumerable
end

class Main
  def run
		puts "Hello Outlook"
		myApp = WIN32OLE::new("outlook.Application")
		WIN32OLE.const_load(myApp, OutlookConst)

		ns = myApp.GetNameSpace("MAPI")
		#ns.Logon # uncomment for online usage
		ff = FolderFinder.new
		flSource = ff.findFolderPath(ns, "Persoonlijke mappen/Postvak IN")
		puts "Found folder, name = #{flSource.name}"
		flTarget = ff.findFolderPath(ns, "Persoonlijke mappen/Postvak IN/TODO mail")
		moveTodoItems(flSource, flTarget)
  end

	def moveTodoItems(flSource, flTarget)
		flSource.Items.each { 
			| msg |
			if (msg.Subject =~ /^TODO/)
				puts "Moving item: #{msg.Subject}"
				msg.Move(flTarget)
			end
		}
	end
  
end

class OutlookConst
end

main = Main.new
main.run

