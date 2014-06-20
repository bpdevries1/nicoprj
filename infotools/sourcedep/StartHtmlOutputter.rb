# StartHtmlOutputter

require "AbstractOutputter.rb"
require "HtmlHelper.rb"

class StartHtmlOutputter < AbstractOutputter

	# def output_all_start
	def prepare_all
		super
		# puts "StartHtmlOutputter.output_all_start called"
		fname_index = URLLocator.instance.outputroot + "/index.html"
		@file_index = File.open(fname_index, "w")
		@file_index.puts "<html><head><title>Index</title>#{HtmlHelper.instance.htmlStyle}</head><body>"
		@file_index.puts "<h3><a href=\"allfiles.html\">All files</a></h3>"
		@file_index.puts "<h3>Start files:</h3>"
	  @file_index.puts "#{HtmlHelper.instance.htmlTable}<tr><th>File</th></tr>"
		@depfiles = DepFileList.instance
	end

	# def output_all_end
	def teardown_all
		# puts "StartHtmlOutputter.output_all_end called"
		@file_index.puts "</body></html>"
		@file_index.close
		super
	end

	def output_root_header(dep_file)
		href = URLLocator.instance.get_deps_href dep_file
		# @file_index.puts "#{href}<br>"
		@file_index.puts "<tr><td>#{href}</td></tr>"
	end

	def output_unhandled_list lst_dep_files
		# close previous table with start-files, need better place for this.
		@file_index.puts "</table>"
		
		@file_index.puts "<hr>"
		@file_index.puts "<h3>Unused files:</h3>"
	  @file_index.puts "#{HtmlHelper.instance.htmlTable}<tr><th>File</th><th>Root parents</th></tr>"
		lst_dep_files.sort.each{|depfile| 
			if depfile.exists
				output_unhandled depfile
			end
		}
	  @file_index.puts "</table>"
	end

	def output_unhandled dep_file
		urlloc = URLLocator.instance
		@file_index.puts "<tr>"
		href = urlloc.get_deps_href(dep_file, "relpath")
		@file_index.puts "<td>#{href}</td>"
		@file_index.puts "<td>"
		
		root_parents = @depfiles.get_root_parents(dep_file)
		root_parents.sort.each {|root| @file_index.puts "#{urlloc.get_deps_href(root, "relpath")}<br>"}
		
		@file_index.puts "</td>"
		@file_index.puts "</tr>"
	end

end
