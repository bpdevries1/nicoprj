# DepParams - parameters of a dependency (call etc)

class DepParams

	attr_reader :lparams

	def initialize (params)
		# @todo: don't split on a space if it is between quotes.
		if params == nil
			@lparams = []
		elsif params.kind_of? String
			@lparams = params.split(" ")
		elsif params.kind_of? Array
			@lparams = params
		else
			puts "DepParams.init: don't know how to handle #{str.to_s}"
			@lparams = []
		end
	end

	def to_s
		@lparams.join(" ")
	end

	def toDotLabel
		ar = @lparams.collect{|param| paramToDotLabel param}
		ar.join("\\n")
	end

	def paramToDotLabel(param)
		# replace \ by \\ 
		# replace newlines by \n
		# replace space by \n
		result = String.new(param)
		# blijkbaar nodig om backslashes zoals onderstaand te vervangen door een dubbele.
		result.gsub!(/\\/, '\\\\\\')
		result.gsub!(/\n/, '\\n')
		# result.gsub!(/ /, '\\n')

		# per line (param): remove everything before last backslash (or slash?)
		result.gsub!(/^.+\\([^\\]+)$/, '\1')
		return result
	end

end
