create index if not exists ix_aggr_run_1 on aggr_run (date_cet);
create index if not exists ix_aggr_page_1 on aggr_page (date_cet);
create index if not exists ix_aggr_slowitem_1 on aggr_slowitem (date_cet);
create index if not exists ix_aggr_sub_1 on aggr_sub (date_cet);
create index if not exists ix_aggr_connect_time_1 on aggr_connect_time (date_cet);
create index if not exists ix_pageitem_gt3_1 on pageitem_gt3 (date_cet);
create index if not exists ix_pagitem_topic_1 on pageitem_topic (date_cet);
create index if not exists ix_domain_ip_time_1 on domain_ip_time (date_cet);
create index if not exists ix_aggr_specific on aggr_specific (date_cet);