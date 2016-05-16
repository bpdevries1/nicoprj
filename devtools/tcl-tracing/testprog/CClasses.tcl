itcl::class ClassB {

	private common CLASSNAME ClassB

	public proc new_instance {} {
		# return [ClassB #auto]
		# set res [ClassB #auto]
		set res [$CLASSNAME #auto]
		puts "res: $res"
		set res2 [itcl::code $res]
		puts "res2: $res2"
		puts "nw: [namespace which $res]"
		return $res2
	}

	private constructor {} {
		# do nothing
	}

	public proc new_instance2 {} {
		# return [itcl::code [ClassB #auto]]
		# return [namespace which [ClassB #auto]]
		return [uplevel {namespace which [ClassB #auto]}]
	}
	
	public method get_value {} {
		return 4242
	}

	public proc proc1 {param} {
		puts "proc1 called: $param"
	}

	public proc proc2 {} {
		puts "proc2 called: $param"
	}

}

itcl::class ClassC {
	public method method1 {ref} {
		puts "ref: $ref"
		puts [$ref get_value]
		ClassB::proc1 abc
	}


}

