# C:\nico\util\lqn\LQN Solvers\lqns.exe 3.10
# C:\nico\util\lqn\LQN Solvers\lqns.exe -p wbgsql-1.lqn
V y
C 1.43649e-007
I 2
PP 4
NP 1
#!Real:  0:00:00.00
#!Solver:    7   0   0         44     6.2857      1.666       1719     245.57     247.72  0:00:00.00 
B 4
wbgsql          : wbgsql          196.075     
wbgsql_cpu      : wbgsql_cpu      196.078     
wbgsql_disk0    : disk0_wbgsql    10000       
wbgsql_disk1    : wbgsql_disk1    10000       
 -1

W 3
wbgsql          : wbgsql          wbgsql_cpu      0            -1 
 -1
wbgsql_cpu      : wbgsql_cpu      disk0_wbgsql    0            -1 
                  wbgsql_cpu      wbgsql_disk1    0            -1 
 -1
 -1


X 4
wbgsql          : wbgsql          0.0051001    -1 
 -1
wbgsql_cpu      : wbgsql_cpu      0.0051       -1 
 -1
wbgsql_disk0    : disk0_wbgsql    0.0001       -1 
 -1
wbgsql_disk1    : wbgsql_disk1    0.0001       -1 
 -1
 -1


VAR 4
wbgsql          : wbgsql          7.20621e-005  -1 
 -1
wbgsql_cpu      : wbgsql_cpu      2.00411e-005  -1 
 -1
wbgsql_disk0    : disk0_wbgsql    1e-008       -1 
 -1
wbgsql_disk1    : wbgsql_disk1    1e-008       -1 
 -1
 -1

FQ 4
wbgsql          : wbgsql          196.075     1            -1 1           
 -1
wbgsql_cpu      : wbgsql_cpu      196.075     0.999981     -1 0.999981    
 -1
wbgsql_disk0    : disk0_wbgsql    196.075     0.0196075    -1 0.0196075   
 -1
wbgsql_disk1    : wbgsql_disk1    196.075     0.0196075    -1 0.0196075   
 -1
 -1

P CPU 1
wbgsql_cpu      1 0   1   wbgsql_cpu      0.960766    0            -1 
 -1
 -1
P Client 1
wbgsql          1 0   1   wbgsql          1.96075e-005 0            -1 
 -1
 -1
P Disk0 1
wbgsql_disk0    1 0   1   disk0_wbgsql    0.0196075   0            -1 
 -1
 -1
P Disk1 1
wbgsql_disk1    1 0   1   wbgsql_disk1    0.0196075   0            -1 
 -1
 -1
 -1

