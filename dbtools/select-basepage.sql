select ts_cet, page_seq, url from pageitem
where ts_cet > '2014-02-23' 
and basepage=1
limit 10;
