create table pageitem_gt3 as
select *
from pageitem
where 1*element_delta > 3000;

