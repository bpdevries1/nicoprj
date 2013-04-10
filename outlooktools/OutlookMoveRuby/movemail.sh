#!/usr/bin/bash

cd /cygdrive/c/nico/nicoprj/outlooktools/outlookmoveruby
export bakfile=/cygdrive/c/nico/projecten/mail/emailfolders-`date +%Y-%m-%d`.xml
rm $bakfile
cp emailfolders.xml $bakfile
# ruby movemail.rb
c:/develop/ruby/bin/ruby.EXE movemail.rb
