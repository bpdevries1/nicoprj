# Action - do combi of traveller/outputter for each given file

require "LoggerFactory.rb"

class Action

	def initialize(elAction, travellers, outputters)
		@log = LoggerFactory.instance.get_logger "action"

		traveller_name = elAction.attributes['traveller']
		@traveller = travellers.find {|traveller| traveller.name == traveller_name}
		if @traveller == nil
			@log.error "Traveller not found: #{traveller_name}"
			return
		end
		
		outputter_name = elAction.attributes['outputter']
		outputter = outputters.find {|outputter| outputter.name == outputter_name}
		if outputter == nil
			@log.error "Outputter not found: #{outputter_name}"
			return
		end
		
		@traveller.add_outputter(outputter)
		@fileset = elAction.elements.to_a("fileset/include").collect{|el| Regexp.new(el.attributes['name'])}
	end

	def do_action
		# @todo check fileset
		# @outputter.output_all_start
		@traveller.prepare_all
		dep_files = DepFileList.instance.lstDepFiles
		dep_files.sort.each {|dep_file| 
			if dep_file.exists and match?(dep_file)
		  	@traveller.travel(dep_file)
		  end
		}
		@traveller.teardown_all
		# @outputter.output_all_end
	end

	def match? (dep_file)
		return @fileset.find {|re| re.match(dep_file.filename)}
	end

end