require "StartHtmlOutputter"
require "rexml/document"
include REXML  # so that we don't have to prefix everything with REXML::...

class TestOutputter

	def run
		puts StartHtmlOutputter.new(Element.new).htmlStyle
	end

end

TestOutputter.new.run