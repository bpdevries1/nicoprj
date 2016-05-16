Scripts to convert csv files to sqlite db.

At first used to convert windows event log csv export to db. Special handling 
required for multi-line strings (enclosed in quotes). And also parsing specific lines in
the text-field.
This csv has no header line.

Further improvements:
* Make general, work with/without header-line, specify fields seperately. 
* Also special handling functions for text-fields (and other fields) 
* declare parsing of date/time field.

See also:
* graphdata/data2sqlite, possibly overlapping code.


