select id, ts_cet, page_seq, url
from pageitem
where domain like '%p4c.philips.com'
limit 10;