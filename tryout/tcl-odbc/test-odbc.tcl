package require tdbc
package require tdbc::odbc

# [2016-12-11 21:56] don't test for now, should check iff windows.
#@test never

set db [tdbc::odbc::connection create db2 "Driver=SQL Server Native Client 11.0;Server=LAPTOP-NICO\\SQLEXPRESS;Database=testndv2;Trusted_Connection=yes;"]
set s [$db prepare "select * from testtb2"]
puts [$s allrows]
$s close
$db close
