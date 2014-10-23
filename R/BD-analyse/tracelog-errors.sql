drop table _temp_trace_errors
CREATE TABLE _temp_trace_errors (Server varchar(255), dayhour datetime, verwerkingstype int, nerrors int, sum_sec real)

insert into _temp_trace_errors
select server, dateadd(hour, datediff(hour, 0, tijdstip), 0)
      ,verwerkingstype
	  ,count(*), sum(0.001*verwerkingstijd)
from dbo.tracelogduration
where verwerkingstype <> 1
group by server, dateadd(hour, datediff(hour, 0, tijdstip), 0)
      ,verwerkingstype
	  