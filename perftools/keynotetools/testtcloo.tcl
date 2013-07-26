# 24-7-2013 onderstaande werkt wel, ook als je package requires omdraait. 
# maar ergens ging het toch fout...

package require ndv
package require TclOO 

oo::class create fruit {
    method eat {} {
        puts "yummy!"
    }
}
oo::class create banana {
    superclass fruit
    constructor {} {
        my variable peeled
        set peeled 0
    }
    method peel {} {
        my variable peeled
        set peeled 1
        puts "skin now off"
    }
    method edible? {} {
        my variable peeled
        return $peeled
    }
    method eat {} {
        if {![my edible?]} {
            my peel
        }
        next
    }
}
set b [banana new]
$b eat               
fruit destroy

# onderstaande geeft nu een error, by design.
# $b eat            


