# C:\nico\util\lqn\LQN Solvers\lqns.exe 3.10
# C:\nico\util\lqn\LQN Solvers\lqns.exe -p wbgsql-2.lqn
V y
C 1.75994e-006
I 3
PP 4
NP 1
#!Real:  0:00:00.00
#!Solver:   11   0   0         67     6.0909     1.5048       2425     220.45     214.54  0:00:00.00 
B 4
wbgsql          : wbgsql          392.149     
wbgsql_cpu      : wbgsql_cpu      196.078     
wbgsql_disk0    : disk0_wbgsql    10000       
wbgsql_disk1    : wbgsql_disk1    10000       
 -1

W 3
wbgsql          : wbgsql          wbgsql_cpu      0.0047984    -1 
 -1
wbgsql_cpu      : wbgsql_cpu      disk0_wbgsql    0            -1 
                  wbgsql_cpu      wbgsql_disk1    0            -1 
 -1
 -1


X 4
wbgsql          : wbgsql          0.0098985    -1 
 -1
wbgsql_cpu      : wbgsql_cpu      0.0051       -1 
 -1
wbgsql_disk0    : disk0_wbgsql    0.0001       -1 
 -1
wbgsql_disk1    : wbgsql_disk1    0.0001       -1 
 -1
 -1


VAR 4
wbgsql          : wbgsql          0.000239025  -1 
 -1
wbgsql_cpu      : wbgsql_cpu      2.00411e-005  -1 
 -1
wbgsql_disk0    : disk0_wbgsql    1e-008       -1 
 -1
wbgsql_disk1    : wbgsql_disk1    1e-008       -1 
 -1
 -1

FQ 4
wbgsql          : wbgsql          202.051     2            -1 2           
 -1
wbgsql_cpu      : wbgsql_cpu      202.051     1.03046      -1 1.03046     
 -1
wbgsql_disk0    : disk0_wbgsql    196.078     0.0196078    -1 0.0196078   
 -1
wbgsql_disk1    : wbgsql_disk1    196.078     0.0196078    -1 0.0196078   
 -1
 -1

P CPU 1
wbgsql_cpu      1 0   1   wbgsql_cpu      0.990049    0            -1 
 -1
 -1
P Client 1
wbgsql          1 0   2   wbgsql          2.02051e-005 0            -1 
 -1
 -1
P Disk0 1
wbgsql_disk0    1 0   1   disk0_wbgsql    0.0196078   0            -1 
 -1
 -1
P Disk1 1
wbgsql_disk1    1 0   1   wbgsql_disk1    0.0196078   0            -1 
 -1
 -1
 -1

