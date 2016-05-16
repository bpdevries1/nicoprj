# tclsh tclsh graph-asmf.tcl c:\nico_share\ITM-data\T20081118
# had eerst 20081101, maar dit is nog zomertijd, en dan warnings van R.

set OUTPUT_BASE=c:\nico_share\ITM-data\Perftest-resource
set ITM_FILE=c:\nico_share\ITM-data\KQITASMF.graphdata
set MSU_FILE=C:\vreen00_CxR_Int2\CxR_IKT\Performance\Monitoring\Mainframe-monitoring\MSU-Data\Q5-2008-all.tsv
set JM_FILE=C:\vreen00_CxR_Int2\CxR_IKT\Performance\Service-Performance-Testen\2008.3\results2008.3.csv
set WORKLOAD_FILE=C:\vreen00_CxR_Int2\CxR_IKT\Performance\Monitoring\Mainframe-monitoring\Workload-data\workload-20081020-20081116-enhanced.tsv
rem set JM_FILE=C:\vreen00_CxR_Int2\CxR_IKT\Performance\Service-Performance-Testen\2008.3\results2008.3.eentje.csv

rem goto nieuw
rem eerst alles
R graph-asmf.R 20081022-100000 20081110-230000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%
R graph-asmf.R 20081020-010000 20081117-230000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%
rem goto end

rem dan details
rem R graph-asmf.R 20081104-120000 20081110-230000 %ITM_FILE% %MSU_FILE% %JM_FILE%
R graph-asmf.R 20081109-230000 20081112-230000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE% 
R graph-asmf.R 20081110-140000 20081110-220000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%
R graph-asmf.R 20081106-070000 20081107-210000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%
R graph-asmf.R 20081103-070000 20081103-210000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%
R graph-asmf.R 20081103-130000 20081103-170000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%
R graph-asmf.R 20081022-090000 20081024-090000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%

:nieuw
rem nieuw voor service-detail-analyse
R graph-asmf.R 20081101-060000 20081101-230000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%
R graph-asmf.R 20081029-160000 20081029-210000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%
R graph-asmf.R 20081031-140000 20081031-190000 %OUTPUT_BASE% %ITM_FILE% %MSU_FILE% %JM_FILE% %WORKLOAD_FILE%

:end
