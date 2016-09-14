# NoTraveller

require "AbstractTraveller.rb"

class NoTraveller < AbstractTraveller

	# attributes
	# Outputter[] @outputters
	# DepFile[] @travelledDepFiles
	# DepFile[] @ignoredDepFiles
	# String[] @startfilenames
	# String[] @ignorefilenames
	# String name
	
	# attr_reader :name, :travelledDepFiles, :ignoredDepFiles

	def initialize(elTraveller)
		super(elTraveller)
	end

  def travel(dep_file)
		travel_root(dep_file)		
	end

	# @todo counting the 'indentation' level may be handy.
	def travel_root (depFile)
		@outputters.each {|outputter| outputter.output_root_header depFile}
		travel_node(depFile, [])
		@outputters.each {|outputter| outputter.output_root_footer depFile}
	end

	# travelpath: which path has been travelled up until this node?
	# if this node is already in the path, stop travelling.
	def travel_node(depFile, travelPath)
		@outputters.each {|outputter| outputter.output_node depFile}
	end

end
