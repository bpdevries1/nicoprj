set fn [function/lambda {args} {body}]

#@test never

keuze:
set res [fn $args]
set res [apply $fn $args]
set res [$fn $args]

#en hierna ook met map etc toepassen.

#had al eens iets met lambda2proc en proc2lambda gedaan.


