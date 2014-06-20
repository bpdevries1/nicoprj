# OutputterFactory

require "DotOutputter.rb"
require "HtmlOutputter.rb"
require "StartHtmlOutputter.rb"
require "LoggerFactory.rb"

class OutputterFactory

	@@log = LoggerFactory.instance.get_logger "outputterfactory"

	# def OutputterFactory::new(elOutput, travellers)
	def OutputterFactory::new(elOutput)
		klass =
    	case elOutput.attributes['type']
      	when "dot"
        	DotOutputter
        when "html"
        	HtmlOutputter
        when "starthtml"
          StartHtmlOutputter
        else
          @@log.error "Outputter type not found: #{elOutput.attributes['type']}"
          nil
      end
    # puts "Making object of type #{klass} for #{filename}" 
    # klass::new(elOutput, travellers)
    klass::new(elOutput)
  end
  
end
