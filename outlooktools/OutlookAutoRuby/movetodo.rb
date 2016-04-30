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
		# flTarget = ff.findFolderPath(ns, "Persoonlijke mappen/Postvak IN/TODO mail")
		# flTarget = ff.findFolderPath(ns, "Persoonlijke mappen/Taken")
		flTarget = ff.findFolderPath(ns, "Personal/Afgehandeld/TRItems")
		
		# @todofile = File.open("d:/aaa/thoughts.txt", "w")
		@todofile = File.open("#{ENV['THINKINGROCK_DIR']}/thoughts.txt", "w")
		
		moveTodoItems(flSource, flTarget)
		@todofile.close
  end

	def moveTodoItems(flSource, flTarget)
		# make a copy first, the original each is too dynamic when items are moved/deleted.
		copy = flSource.Items.collect {|el| el}
		copy.each { 
			| msg |
			if (msg.Subject =~ /^TODO/)
				puts "Moving item: #{msg.Subject}"
				copy_to_file(msg)
				msg.Move(flTarget)
			end
		}
	end

	def copy_to_file(msg)
		subject = msg.Subject
		tekst = msg.Body
		# toch geen streepje tussen regels, alleen maar lastig met verwijderen.
		tekst.gsub!("\n", " ")
		tekst.gsub!("\r", "")
		# TODO aan begin verwijderen
		# subject.gsub!("^TODO ", "")
		subject.gsub!(/^TODO /, "")
		# standaard BD footer verwijderen.
		tekst.gsub!(/Met vriendelijke groet,  Nico de Vreeze.*$/, "")
		tekst.gsub!(/-+ De Belastingdienst gebruikt.*$/,"")
		#tekst1 = tekst.gsub("[a\-]","")
		#tekst2 = tekst.gsub("De Belastingdienst gebruikt", "")
		#puts("tekst1: #{tekst1}")
		#puts("tekst2: #{tekst2}")
		@todofile.puts("#{subject}: #{tekst}")
	end
  
end

class OutlookConst
end

main = Main.new
main.run

