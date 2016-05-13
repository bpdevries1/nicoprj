# C:\nico\util\lqn\LQN Solvers\lqns.exe 3.10
# C:\nico\util\lqn\LQN Solvers\lqns.exe -p wbgsql-10.lqn
V y
C 1.03083e-006
I 2
PP 4
NP 1
#!Real:  0:00:00.00
#!Solver:    7   0   0         45     6.4286     1.6782       1758     251.14     244.99  0:00:00.00 
B 4
wbgsql          : wbgsql          1960.75     
wbgsql_cpu      : wbgsql_cpu      196.078     
wbgsql_disk0    : disk0_wbgsql    10000       
wbgsql_disk1    : wbgsql_disk1    10000       
 -1

W 3
wbgsql          : wbgsql          wbgsql_cpu      0.0453677    -1 
 -1
wbgsql_cpu      : wbgsql_cpu      disk0_wbgsql    0            -1 
                  wbgsql_cpu      wbgsql_disk1    0            -1 
 -1
 -1


X 4
wbgsql          : wbgsql          0.0504678    -1 
 -1
wbgsql_cpu      : wbgsql_cpu      0.0051       -1 
 -1
wbgsql_disk0    : disk0_wbgsql    0.0001       -1 
 -1
wbgsql_disk1    : wbgsql_disk1    0.0001       -1 
 -1
 -1


VAR 4
wbgsql          : wbgsql          0.00717225   -1 
 -1
wbgsql_cpu      : wbgsql_cpu      2.00411e-005  -1 
 -1
wbgsql_disk0    : disk0_wbgsql    1e-008       -1 
 -1
wbgsql_disk1    : wbgsql_disk1    1e-008       -1 
 -1
 -1

FQ 4
wbgsql          : wbgsql          198.146     10           -1 10          
 -1
wbgsql_cpu      : wbgsql_cpu      198.146     1.01055      -1 1.01055     
 -1
wbgsql_disk0    : disk0_wbgsql    196.078     0.0196078    -1 0.0196078   
 -1
wbgsql_disk1    : wbgsql_disk1    196.078     0.0196078    -1 0.0196078   
 -1
 -1

P CPU 1
wbgsql_cpu      1 0   1   wbgsql_cpu      0.970916    0            -1 
 -1
 -1
P Client 1
wbgsql          1 0   10  wbgsql          1.98146e-005 0            -1 
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

