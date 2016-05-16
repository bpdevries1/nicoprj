@echo off
setlocal
net use /persistent:yes
LOOP: net use NET: /delete
LOOP: net use NET: \\IP\DRIVE$ PASSWORD /user:LOGIN
LOOP: mkdir NET:\DIR
