select * from book limit 10;

select * from itemgroup;

insert into itemgroup (name, notes, tags)
values ('First group', 'Notes first group', 'title,year,npages');

select * from itemgroupquery;

insert into itemgroupquery (itemgroup_id, name, type, query, notes)
values (1, 'First-IG-query', 'add', 'select * from book where title like ''%Clojure%''', 'Clojure books add query');

select * from member;

insert into member (itemgroup_id, type, item_table, item_id)
select 1, 'manual', 'book', b.id
from book b
limit 5;

select * from relation;

insert into relation (from_table, to_table, from_id, to_id, type)
values ('book', 'book', 99, 37, 'another');

insert into relation (from_table, to_table, from_id, to_id, type)
values ('book', 'book', 99, 38, 'another');

select * from tags;

insert into tags (item_table, item_id, tags)
values ('book', 99, 'year=1900,npages=200');

