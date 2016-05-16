option explicit

dim a, arg, oArgs, ArgNum
a = 0

Set oArgs = WSCript.arguments
ArgNum = oArgs.Count

if ArgNum <> 1 then
   WSCript.echo "Syntax: cscript <Script> filename_root"
   WScript.quit(1)
end if

dim filename_root, oldfilename, pos,newname
oldfilename = oArgs(0)

rem Remove .xls file extension if it was provided
dim ext
ext = right( oldfilename, 4 )
if lcase( ext ) = ".xls" then
 oldfilename = left( oldfilename, len( oldfilename ) - 4 )
end if

pos = instr(oldfilename, " ")

if pos > 0 then

 newname = right(oldfilename, len(oldfilename) - instrrev(oldfilename, "\"))
 newname = replace(newname," ","_")
 filename_root = left(oldfilename, instrrev(oldfilename, "\")) & newname

 dim oShell
 set oShell = Wscript.CreateObject("WScript.Shell")
 Wscript.echo "cmd.exe /c ren """ & oldfilename & ".xls"" " & newname & ".xls"
 oShell.run "cmd.exe /c ren """ & oldfilename & ".xls"" " & newname & ".xls"

else
 filename_root = oldfilename
end if

dim app
set app = createobject("Excel.Application")
   
dim wb
set wb = app.workbooks.open( filename_root & ".xls" )

const xlXMLSpreadsheet = 46
'const xlCSV = 6
const xlTSV = 3

app.DisplayAlerts = false
dim sht
for each sht in wb.worksheets
 sht.activate
 dim output_filename
 output_filename = filename_root & "_" & replace( sht.name, " ", "_" ) & ".tsv"
 wb.saveAs output_filename, xlTSV
next
'wb.saveAs filename_root & ".xml", xlXMLSpreadsheet
app.DisplayAlerts = true

wb.close false

'app.close

WScript.quit 

