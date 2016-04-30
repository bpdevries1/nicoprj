# EmailFolders.rb - manage relation between email adresses and folders to put them in
#
# address => Array of MailFolder
# MailFolder: name, outlook_folder
# @todo: for sent items ook naar to kijken, niet alleen naar sendername.
# @todo?: volgorde in lijst aanbrengen? meest gebruikte als eerste noemen?

require "rexml/document"
include REXML  # so that we don't have to prefix everything with REXML::...

require 'find'
require 'fileutils'
include FileUtils::Verbose


class EmailFolders

	# instance var library: hashtable:
	#   key: address (string).
	#   value: tuple: <auto, list of folders>
	#   if auto == 1 (true) => count(list) == 1

	def initialize (a_filename, a_folder_finder)
		@filename = a_filename
		@folder_finder = a_folder_finder
		MailFolder.set_folder_finder(@folder_finder)
		# @library = Hash.new
		read_library
	end

	def find_folders(msg)
		# return Array.new	
		# return @library[msg_get_key(msg)]
		# wil nu eigenlijk een inject methode...
		result = Array.new
		msg_get_keys(msg).each {
			|key| 
			# list = @library[key].list
			tuple = @library[key]
			list = nil
			list = tuple.list if tuple != nil
			if list != nil
				result = result | list
			end
		}
		return result
	end

	# NdV 2-10-2009:
	# geef alleen 'verwijderde items' terug als dit voor alle keys het antwoord is
	# wanneer auto-delete? als van vage afzender of als fw naar todo@ndv. Bij fw geen andere items, dus dan length==1
	# bij vage afzender kan het zijn dan 'ie naar veel meer gestuurd is, dan eigenlijk alleen naar from kijken.
	# veilige keus is vooralsnog om te checken op length==1
	def find_auto_folder(msg)
		result = nil
		msg_get_keys(msg).each {
			|key| 
			tuple = @library[key]
			result = tuple.list[0] if (tuple != nil) && tuple.auto
		}
		if (result != nil) && (result.path =~ /Verwijderde items/)
			puts "*** #keys for auto-delete (moet 1 zijn): #{msg_get_keys(msg).length}"
      puts "*** keys: #{msg_get_keys(msg).join('*')}"
			result = nil if msg_get_keys(msg).length != 1
		end
    if (result != nil)
			puts "*** #keys for auto-move: #{msg_get_keys(msg).length}"
      puts "*** keys: #{msg_get_keys(msg).join('*')}"
    end
		return result
	end

	def add_folder(msg, mail_folder)
		puts "Adding folder #{mail_folder.path} for #{msg.Subject}"
		keys = msg_get_keys(msg)
		keys.each {
			|key|
			tuple = @library[key]
			list = nil
			list = tuple.list if tuple != nil
			# list = @library[key].list
			if list == nil
				list = Array.new
				tuple = LibraryTuple.new(false, list)
				# @library[key] = list
				@library[key] = tuple
			end
			# list << mail_folder
			# put new item at the top
			list.insert(0, mail_folder)
		}
	end

	# move folder to top of lists for each recipient
	# only move it if it is already in the list (and the list exists)
	def move_to_top(msg, mail_folder)
		keys = msg_get_keys(msg)
		keys.each {
			|key|
			tuple = @library[key]
			list = nil
			list = tuple.list if tuple != nil
			if list != nil
				item = list.delete(mail_folder)
				list.insert(0, item) if item != nil
			end
		}
	end
	
	def set_auto_folder(key, mail_folder)
		puts "Adding auto folder #{mail_folder.path} for key"
		list = Array.new
		list << mail_folder
		tuple = LibraryTuple.new(true, list)
		@library[key] = tuple
	end

	def close
		save_library
	end

	def msg_get_keys(msg)
		# 2-10-2009 blijkbaar soms gekke mailtjes, zonder recipients veld/method
		begin
			result = msg.recipients.collect{|rec| rec.address}
			# msg.replyrecipients.collect{|rec| rec.address}
			# replyrecipients is vaak (altijd?) leeg, dus maak een echte reply
      #puts "result na recipients.collect: #{result.join('*')}"
			# 7-10-2009 ivm auto-delete: wil niet sender dubbel, dus nu alleen sendername, niet reply.recipient.
      #reply = msg.reply
			#result = result | reply.recipients.collect{|rec| rec.address}
      #puts "result na reply.collect: #{result.join('*')}"
			# recipients van reply soms ook leeg (Marco), dus ook SenderName toevoegen.
			result << msg.SenderName
      #puts "result na add sendername: #{result.join('*')}"
			#reply = nil
			return result.find_all{|str| !is_nico(str)}
		rescue
			# return empty list.
			return Array.new
		end
	
	end

	def is_nico(str)
		return true if str == "Vreeze, Nico de"
		return true if str == "nico.de.vreeze@xs4all.nl"
		return true if str == "vreeze42@xs4all.nl"
		return true if str == "nico.de.vreeze@ordina.nl"
		return true if str == "Nico de Vreeze"
    return true if str == "/O=WORK/OU=FIRST ADMINISTRATIVE GROUP/CN=RECIPIENTS/CN=NDVREEZE"
		# ook checken of 'ie leeg is.
		return true if str == ""		
		return false
	end

	def save_library
		doc = Document.new
		el_root = Element.new("EmailFolders")
		doc.add_element(el_root)
		@library.sort.each {
			|el|
			key = el[0]
			# auto = el[1].auto?"true":"false"
			auto = "false"
			auto = "true" if el[1].auto
	    # puts "warn: auto == true (#{el[1].auto})" if el[1].auto

			list = el[1].list
			
			el_address = el_root.add_element "Address", {"name" => key, "auto" => auto}
			list.each {
				|mailfolder| 
				el_address.add_element "MailFolder", {"path" => mailfolder.path} 
			}
		}
		File.open(@filename, "w+") {
			|file|
			# doc.write(file, 0, false, false)
			doc.write(file, 2)
			# PROBLEM with Ruby 1.8.6 (per 6-1-2008), so a bit different:
			# problem is that the xml file is not pretty formatted anymore, but alas, it works again.
			# doc.write(file, -1, false, false)
		}
	end

	def save_library_old
		doc = Document.new
		el_root = Element.new("EmailFolders")
		doc.add_element(el_root)
		@library.each {
			|key, list| 
			# print key, " is ", value, "\n" 
			#el_address = Element.new "Address", {"name" => key}
			#el_root.add_element el_address
			el_address = el_root.add_element "Address", {"name" => key}
			list.each {
				|mailfolder| 
				# el_mailfolder = Element.new "MailFolder", {"path" => mailfolder.path} 
				# el_address.add_element el_mailfolder
				el_address.add_element "MailFolder", {"path" => mailfolder.path} 
			}
		}
		File.open(@filename, "w+") {
			|file|
			doc.write(file, 2)
		}
	end

	def read_library
		@library = Hash.new
		return if !FileTest.exists?(@filename)
		
		file = File.new(@filename)
		doc = Document.new file
		root = doc.root

		root.elements.to_a("Address").each {
			|el_address|
			key = el_address.attributes["name"]
			list = el_address.elements.to_a("MailFolder").collect{
				|el_mailfolder|
				path = el_mailfolder.attributes["path"]
				# folder = @folder_finder.find(path)
				folder = nil
				MailFolder.get(path, folder)
			}
			attr_auto = el_address.attributes["auto"]
			auto = false
			auto = true if attr_auto == "true"
			tuple = LibraryTuple.new(auto, list)
			# @library[key] = list
			@library[key] = tuple
		}
		
	end

	def read_library_old
		@library = Hash.new
		return if !FileTest.exists?(@filename)
		
		file = File.new(@filename)
		doc = Document.new file
		root = doc.root

		root.elements.to_a("Address").each {
			|el_address|
			key = el_address.attributes["name"]
			list = el_address.elements.to_a("MailFolder").collect{
				|el_mailfolder|
				path = el_mailfolder.attributes["path"]
				folder = @folder_finder.find(path)
				MailFolder.get(path, folder)
			}
			@library[key] = list
		}
		
	end


end

class MailFolder

	@@mail_folders = Hash.new
	@@folder_finder = nil
	
	# class method get : check the lib of mail folders (hash)
	def MailFolder.get(a_path, an_outlook_folder)
		res = @@mail_folders[a_path]
		if res == nil
			res = MailFolder.new(a_path, an_outlook_folder)
			@@mail_folders[a_path] = res
		end
		return res
	end

	def MailFolder.set_folder_finder(a_folder_finder)
		@@folder_finder = a_folder_finder
	end

	# attr_reader :path, :outlook_folder
	attr_reader :path

	def initialize(a_path, an_outlook_folder)
		@path = a_path
		@outlook_folder = an_outlook_folder
	end

	def outlook_folder
		if @outlook_folder == nil
			@outlook_folder = @@folder_finder.find(path)		
		end
		return @outlook_folder
	end

end

class LibraryTuple
	# attr moet voor elke instance var apart worden aangeroepen.
	attr :auto
	attr :list

	def initialize(auto, list)
  	@auto = auto
    @list = list
    # puts "warn: auto == 1" if auto == 1
  end
	
end

