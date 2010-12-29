set bakfile=movemail-%_date.xml
del /q %bakfile%
copy movemail.xml %bakfile%
ruby movemail.rb
