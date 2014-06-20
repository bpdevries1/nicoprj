# AbstractOutputter.rb

require "URLLocator.rb"
require "LoggerFactory.rb"

class AbstractOutputter
	attr_reader :name

	def initialize(elOutputter)
		@log = LoggerFactory.instance.get_logger "abstractoutputter"
		@name = elOutputter.attributes['name']
		@outputroot = elOutputter.attributes['outputroot']
		URLLocator.instance.outputroot = @outputroot
	end

	def output_root_header(depFile)
		# nothing
	end

	def output_root_footer(depFile)
		# nothing
	end

	def output_node(depFile)
		# nothing
	end

	def output_noderef(ref)
		# nothing
	end

	def prepare_all
	
	end

	def teardown_all
	
	end

	def output_all_start
		@log.error "deprecated: output_all_start for: #{self.class.to_s}"
	end

	def output_all_end
		@log.error "deprecated: output_all_end for: #{self.class.to_s}"
	end

	def output_unhandled_list lst_dep_files
	
	end

	def make_dir dirname
		Dir.mkdir dirname unless FileTest.exist?(dirname)
	end

end