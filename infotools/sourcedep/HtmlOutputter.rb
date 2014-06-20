# HtmlOutputter

require "AbstractOutputter.rb"
require "LoggerFactory.rb"
require "URLLocator.rb"
require "HtmlHelper.rb"

class HtmlOutputter < AbstractOutputter

	def initialize(elOutput)
		super(elOutput)
		@log = LoggerFactory.instance.get_logger "htmlout"
		make_output_dirs
	end

	def make_output_dirs
		make_dir @outputroot
		make_dir @outputroot + "/deps"
	end

	# def output_all_start
	def prepare_all
		fname_all = URLLocator.instance.outputroot + "/allfiles.html"
		@file_all = File.open(fname_all, "w")
		@file_all.puts "<html><head><title>All files</title>#{HtmlHelper.instance.htmlStyle}</head><body>"
	end

	# def output_all_end
	def teardown_all
		@file_all.puts "</body></html>"
		@file_all.close
	end

	def output_root_header(depFile)
		@log.debug "output_root_header for: " + depFile.to_s
		# fnameHtml = get_htmlfilename depFile
		fnameHtml = URLLocator.instance.get_deps_loc depFile
		fileHtml = File.open(fnameHtml, "w")
		writeHeader(fileHtml, depFile)
		writeLocation(fileHtml, depFile)
		writeCalls(fileHtml, depFile)
		writeCalledBy(fileHtml, depFile)
		writeGraph(fileHtml, depFile)		
		writeFooter(fileHtml, depFile)
		fileHtml.close
		
		add_all depFile
	end

	def add_all (depFile)
		urlFile = URLLocator.instance.get_deps_href(depFile, "relpath")
		@file_all.puts "#{urlFile}<br>"
	end

	def	writeHeader(fileHtml, depFile)
		fileHtml.puts "<html><head><title>#{depFile.filename}</title>#{HtmlHelper.instance.htmlStyle}</head><body>"
	end

	def	writeLocation(fileHtml, depFile)
		url = URLLocator.instance.get_source_url depFile
		fileHtml.puts "Source: <a href=\"#{url}\">#{depFile.fullpath}</a>"
		fileHtml.puts "<hr>"
	end

	def	writeCalls(fileHtml, depFile)
	  fileHtml.puts "<h3>Calls</hr>"
	  
	  refs = depFile.refs.find_all{|ref| ref.source == depFile}
	  if refs.length == 0
	  	fileHtml.puts "None"
	  else
	  	writeRefsTable(fileHtml, refs, "Callee")
		end
		fileHtml.puts "<hr>"
	end

	def	writeCalledBy(fileHtml, depFile)
	  fileHtml.puts "<h3>Called by</hr>"
	  refs = depFile.refs.find_all{|ref| ref.sink == depFile}
	  if refs.length == 0
	  	fileHtml.puts "None"
	  else
	  	writeRefsTable(fileHtml, refs, "Caller")
		end

		fileHtml.puts "<hr>"
	end

	def writeRefsTable(fileHtml, refs, caller_callee)
	  # fileHtml.puts "<table border=\"1\"><tr><th>#{caller_callee}</th><th>Type</th><th>Arguments</th></tr>"
	  fileHtml.puts "#{HtmlHelper.instance.htmlTable}<tr><th>#{caller_callee}</th><th>Type</th><th>Arguments</th></tr>"
		# only traverse refs if this node is the source
		refs.each {
			|ref|
			fileHtml.puts "<tr>"
			# fileHtml.puts "<td>#{ref.sink.filename}</td>"
			dep_file = (caller_callee == "Callee" ? ref.sink : ref.source)
			href = URLLocator.instance.get_deps_href dep_file
			fileHtml.puts "<td>#{href}</td>"
			fileHtml.puts "<td>#{ref.reftype}</td>"
			fileHtml.puts "<td>#{ref.dep_params.to_s}</td>"
			fileHtml.puts "</tr>"
		}
	  fileHtml.puts "</table>"
	end

	# @pre: a map file should exist for the graph. If not, an empty map is used for the graph.
	def	writeGraph(fileHtml, depFile)		
		urlImg = URLLocator.instance.get_image_url depFile
		
		fileHtml.puts "<IMG SRC=\"#{urlImg}\" ALT=\"Callgraph\" BORDER=\"0\" USEMAP=\"#map\">"
		fileHtml.puts "<MAP NAME=\"map\">"

		fullpath = URLLocator.instance.get_map_loc(depFile)
		if FileTest.exists?(fullpath)
			f = File.new(fullpath)
			text = f.read
			f.close
			fileHtml.puts text
		else
			@log.warn "Mapfile doesn't exists: #{fullpath}"	
		end

		fileHtml.puts "</MAP>"
	
	end
	
	def	writeFooter(fileHtml, depFile)
		fileHtml.puts "</body></html>"
	end


end
