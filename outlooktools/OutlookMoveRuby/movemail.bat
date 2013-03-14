rem set bakfile=emailfolders-%_date.xml
set bakfile=c:\nico\projecten\mail\emailfolders-%_date.xml
del /q %bakfile%
copy emailfolders.xml %bakfile%
ruby movemail.rb
