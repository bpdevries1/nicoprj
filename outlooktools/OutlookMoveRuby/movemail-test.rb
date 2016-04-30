# [2015-11-09 10:02:47] test voor Rabo, eerst 1 mailtje moven.

require 'win32ole'
# require "FolderFinder.rb"
# require "c:/nico/nicoprj/outlooktools/OutlookMoveRuby/FolderFinder.rb"
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
		puts "Outlook Move Ruby"
		
		# myApp = WIN32OLE::new("outlook.Application")
		
		myApp = WIN32OLE.connect("Outlook.Application")
		# myApp = WIN32OLE.new('Outlook.Application')
		WIN32OLE.const_load(myApp, OutlookConst)

		ns = myApp.GetNameSpace("MAPI")
		olFolderInbox = 6; # according to http://stackoverflow.com/questions/5022532/retrieving-outlook-inbox-and-sent-folders-in-delphi-using-ole
		inbox = ns.GetDefaultFolder(olFolderInbox);
		
		#ns.Logon # uncomment for online usage
		@ff = FolderFinder.new
		@ff.set_namespace(ns)
		
		# @folder_chooser = FolderChooser.new
		
		# @email_folders = EmailFolders.new("c:/nico/outlook/emailfolders.xml", @ff)

		# handle_folder(ns, "Persoonlijke mappen/Postvak IN")
		# handle_folder(ns, "Mailbox - Nico de Vreeze/Inbox")
		#handle_folder_name(ns, "nico.de.vreeze@philips.com/Inbox")
		# handle_folder(ns, inbox)
		@log.info("Moving items: start")
		handle_folder_name(myApp, ns, "/Nico.de.Vreeze@rabobank.com/Diversen/Test")
		# handle_folder_name(myApp, ns, "/Nico.de.Vreeze@rabobank.com/Drafts")
		@log.info("Moving items: finished")
		# handle_folder(ns, "Persoonlijke mappen/Verzonden items")

		# handle_todo_folder(ns, "Persoonlijke mappen/Taken", "Personal/Taken/Afgeronde taken")

		# @email_folders.close
  end

	def handle_folder_name(myApp, ns, folder_name)
		fl_source = @ff.find_folder_path(ns, folder_name)
		puts "Found folder, name = #{fl_source.name}"
		fl_target = @ff.find_folder_path(ns, "/Nico.de.Vreeze@rabobank.com/Diversen/Test2")
		handle_items_test(myApp, fl_source, fl_target)
	end
	
	# @param folder outlook folder object
	def handle_folder(ns, folder)
	  handle_items(folder)
	end  
	  
    def show_methods(item)
		puts "Available methods:"
		methods = []
		item.ole_methods.each do |method|
			methods << method.to_s
		end
		puts methods.uniq.sort	
		puts "------"
	end
	  
	def handle_items_test(myApp, fl_source, fl_target)
		# make a copy first, the original each is too dynamic when items are moved/deleted.
		copy = fl_source.Items.collect {|el| el}
		total = copy.size
		@log.info("#items in #{fl_source.name}: #{total}")
		@log.info("#items in orig: #{fl_source.Items.count}")
		index = 1
		@nfailed = 0
		copy.each {
			|msg| 
			# choice = handle_item(msg, index, total)
			# move_item_test(msg, index, total, fl_target)
			copy_item_test(msg, index, total, fl_target)
			# create_item_test(myApp, msg, fl_target)
			# log_details_item(myApp, msg)
			# show_methods(msg)
			# show_methods(fl_source)
			index += 1
			# break if choice.action == "quit"
			
			# nu eerst sowieso break, maar 1 item moven.
			# break
		}
	end

	def move_item_test(msg, index, total, fl_target)
		show_message(msg)
		# move_item(msg, fl_target)
		msg.Move(fl_target)
	end

	def log_details_item(myApp, msg)
		show_message(msg)

	end

	def temp1
		msg2.Attachments.collect {|el| el}.each {
		  |att|
		  filename = "c:\\PCC\\Nico\\aaa\\Test NdV.pdf"
		  @log.info("Save to #{filename}")
		  att.SaveAsFile(filename)
		  @log.info("type: #{att.Type}, pos: #{att.Position}, displayname: #{att.DisplayName}, patname: #{att.PathName}, filename: #{att.FileName}")
		  pos = att.Position
		  if (pos == 0)
			pos = 1
		  end
		  @log.info("type: #{att.Type}, pos: #{pos}, displayname: #{att.DisplayName}, patname: #{att.PathName}, filename: #{att.FileName}")
		  msg2.Attachments.Add(filename, att.Type, pos, "Test NdV.pdf")
		  att.Delete()
		}		
	end
	
	def temp2
		msg2.Attachments.each {
		  |att|
		  @log.info("type: #{att.Type}, pos: #{att.Position}, displayname: #{att.DisplayName}, patname: #{att.PathName}, filename: #{att.FileName}")
		  #msg2.Attachments.Add(filename, att.Type, pos, "Test NdV.pdf")
		  #att.Delete()
		  # [2015-11-16 16:18:48] deze lijkt niet te werken, dus mogelijk toch via file doen. Add+Delete.
		  att.DisplayName = "Test NdV.pdf"
		}		
	
	end
	
	def copy_item_test(msg, index, total, fl_target)
		show_message(msg)
		# move_item(msg, fl_target)
		msg2 = msg.Copy()
		msg2.MessageClass = "IPM.Note"
		msg2.Subject = "Test NdV - #{msg.Subject}"
		# attachment renamen. Met kopie werken, in place updates.
		msg2.Attachments.collect {|el| el}.each {
		  |att|
		  filename = "c:\\PCC\\Nico\\aaa\\Test NdV.pdf"
		  @log.info("Save to #{filename}")
		  att.SaveAsFile(filename)
		  @log.info("type: #{att.Type}, pos: #{att.Position}, displayname: #{att.DisplayName}, patname: #{att.PathName}, filename: #{att.FileName}")
		  pos = att.Position
		  if (pos == 0)
			pos = 1
		  end
		  @log.info("type: #{att.Type}, pos: #{pos}, displayname: #{att.DisplayName}, patname: #{att.PathName}, filename: #{att.FileName}")
		  att.Delete()
		  msg2.Attachments.Add(filename, att.Type, pos, "Test NdV.pdf")
		}		
		
		begin
			msg2.Save()
			msg2.Move(fl_target)
		rescue
			# als save niet lukt, dan deleten.
			msg2.Delete()
			@log.info("Save not possible for msg with subject: #{msg.Subject}")
			@nfailed += 1
			if (@nfailed >= 3)
				@log.warn("too many errors, exit.")
				exit
			end
		end
	end
	
	def create_item_test(myApp, src_msg, fl_target)
		@log.info("Creating item from template.")
		# 2 is een contact, 0 is een mailitem.
		msg = myApp.CreateItem(0)
		msg.Subject = "Test NdV: #{src_msg.Subject}"
		msg.Body = src_msg.Body
		# SentOn read-only? SenderName ook? En To en CC?
		# Received-On wordt automatisch gevuld met huidige tijdstip, is mooi.
		
		# msg.SentOn = src_msg.SentOn
		# msg.Recipients.Add("dummy@dummy98789xzcv.nl")
		
		# Send gaat 'em ook echt sturen via Exchange, wil je niet.
		# msg.Send()
		
		src_msg.Recipients.each {
		  |recp|
		  msg.Recipients.Add(recp)
		}

		# todo testen met >1 attachment in een msg.
		src_msg.Attachments.each {
		  |att|
		  # msg.Attachments.Add(att)
		  # filename = "c:\\PCC\\Nico\\aaa\\att.bin"
		  filename = "c:\\PCC\\Nico\\aaa\\#{att.FileName}"
		  @log.info("Save to #{filename}")
		  att.SaveAsFile(filename)
		  @log.info("type: #{att.Type}, pos: #{att.Position}, displayname: #{att.DisplayName}, patname: #{att.PathName}, filename: #{att.FileName}")
		  pos = att.Position
		  if (pos == 0)
			pos = 1
		  end
		  msg.Attachments.Add(filename, att.Type, 1, att.DisplayName)
		}
		
		# Save na Send werkt niet.
		msg.Save()
		msg.Move(fl_target)
	end

	
	def show_message(msg)
		puts "-" * 78
		# 8-5-09 SentOn is niet altijd beschikbaar blijkbaar.
		begin
			puts "Date: #{msg.SentOn}"
		rescue
			puts "Date: <unknown>"
		end
		begin
			puts "From: #{msg.SenderName}"
		rescue
			puts "From: <unknown>"
		end
		# to en CC niet bekend bij agenda items
		begin
			puts "To: #{msg.To}"
			puts "Cc: #{msg.Cc}" if msg.Cc != ""
		rescue
			puts "To: <unknown>"
			puts "CC: <unknown>"
		end
		puts "Subject: #{msg.Subject}"
		puts "Creation time: #{msg.CreationTime}"
		puts "Expiry time: #{msg.ExpiryTime}"
		puts "Mileage: #{msg.Mileage}"
		puts "OutlookInternalVersion: #{msg.OutlookInternalVersion}"
		puts "OutlookVersion: #{msg.OutlookVersion}"
		puts "RemoteStatus: #{msg.RemoteStatus}"
		puts "Saved: #{msg.Saved}"
		puts "NoAging: #{msg.NoAging}"
		puts "MessageClass: #{msg.MessageClass}"
		puts "Class: #{msg.Class}"
		
		# [2015-11-16 15:28:06] new:
		puts "ConversationID: #{msg.ConversationID}"
		puts "EntryID: #{msg.EntryID}"
		puts "ReceivedByEntryID: #{msg.ReceivedByEntryID}"
		puts "ReceivedOnBehalfOfEntryID: #{msg.ReceivedOnBehalfOfEntryID}"
		puts "UserProperties: #{msg.UserProperties}"
		puts "ItemProperties: #{msg.ItemProperties}"
		# puts "HashCode: #{msg.HashCode}"
		# puts "GetHashCode: #{msg.GetHashCode}"
		
		# only print first 500 characters of Body. 
		# NdV 2-10-2009 sometimes a message without a body
		begin
			# nu even de body niet.
			# puts "#{msg.Body[0,80]}"
		rescue 
		end
		puts "---"
	end
	
	def move_item(msg, mail_folder_to)
		puts "Moving item: #{msg.Subject} => #{mail_folder_to.path}"
		msg.Move(mail_folder_to.outlook_folder) if mail_folder_to.outlook_folder != nil 
	end

end

class OutlookConst
end

main = Main.new
main.run

