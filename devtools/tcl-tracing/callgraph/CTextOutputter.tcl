package require Itcl

itcl::class CTextOutputter {

	public proc new_instance {} {
		return [namespace which [[info class] #auto]]
		# return [CTextOutputter #auto] ; # gaat fout, wegens namespace.
	}
	
	public method output_line {line} {
		puts $line
	}
	
	public method output_call {caller_class caller_method callee_class callee_method} {
		puts "$caller_class.$caller_method => $callee_class.$callee_method"
	}
	
}

