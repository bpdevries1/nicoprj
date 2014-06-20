# DepFileRef - referentie tussen 2 files.

class DepFileRef
	# source en sink verwijzen naar DepFile's, reftype is vooralsnog een string.
	# reftype voorbeelden: call, source/require, in/out/inout.
	attr_accessor :source, :sink, :reftype, :dep_params

	def initialize(source, sink, reftype, dep_params=nil)
		@source = source
		@sink = sink
		@reftype = reftype
		@dep_params = dep_params
	end
	
	def to_s
		result = "#{source.filename} => #{sink.filename} [#{reftype}]"
		result += " (#{@dep_params.to_s})" unless @dep_params == nil
		return result
	end
	
	def <=>(other)
		res = (source <=> other.source)
		if (res == 0)
			res = (sink <=> other.sink)
		end
		return res
	end
	
	# used in Travellers, to determine if the ref from source to sink has already been handled.
	def equals_source_sink?(other)
		return ((@source == other.source) && (@sink == other.sink))
	end
end

