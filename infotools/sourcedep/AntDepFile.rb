# AntDepFile

require "rexml/document"
include REXML  # so that we don't have to prefix everything with REXML::...

require "DepFile.rb"

class AntDepFile < DepFile

	def depFileType
		"Ant"
	end

	def readFile
		if FileTest.exists?(fullpath)
			#file = File.new(fullpath)
			#doc = Document.new(file)
			#root = doc.root
			
			root = Document.new(File.new(fullpath)).root
			
			root.elements.to_a("//import").each {|imp| handleImport imp}
			# execs = root.elements.to_a("//exec").each {|ex| handleExec ex}
			root.elements.to_a("//exec").each {|ex| handleExec ex}
			root.elements.to_a("//ant").each {|ant| handleAnt ant}
		end
	end

	def handleImport(imp)
		# puts "#{@filename} => #{imp.attributes['file']}"
		addRef imp.attributes['file'], "import", nil
	end

	def handleExec(ex)
		executable = ex.attributes['executable']
		if (executable == "${cmdexe}")
			args = ex.elements.to_a("arg")
			# first arg is always /c, second the batchfile and the rest the params of the batchfile
			
			puts "Warning: args size < 2: #{args}" if args.length < 2

			batchfile = getArgValue args[1]
			params = args[2...args.length].collect{|arg| getArgValue arg}
			addRef batchfile, "exec", params
		elsif (executable == "${tclsh}")
			args = ex.elements.to_a("arg")
			# first arg is always the batchfile and the rest the params of the batchfile
			
			puts "Warning: args size < 1: #{args}" if args.length < 1

			tclfile = getArgValue args[0]
			params = args[1...args.length].collect{|arg| getArgValue arg}
			addRef tclfile, "calltcl", params
		else
		  puts "Ant->Exec unhandled: #{@filename} => #{ex.attributes['executable']}"
		end
	end

# <ant antfile="build-run.xml" target="runtest" inheritall="true"/>			
	def handleAnt(ant)
		antfile = ant.attributes['antfile']
		target = ant.attributes['target']
		addRef antfile, "ant", target
	end

	def getArgValue arg
		return arg.attributes['value'] if arg.attributes['value'] != nil
		return arg.attributes['file'] if arg.attributes['file'] != nil
	end

end
