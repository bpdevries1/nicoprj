package require tdbc
package require tdbc::odbc

set db [tdbc::odbc::connection create db2 "Driver=SQL Server Native Client 11.0;Server=LAPTOP-NICO\\SQLEXPRESS;Database=testndv2;Trusted_Connection=yes;"]
set s [$db prepare "select * from testtb2"]
puts [$s allrows]
$s close
$db close
