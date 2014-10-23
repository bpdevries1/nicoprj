# html lib

html.header = function(fo, title, heading1=TRUE) {
  str = concat("<html>
  <head><title>", title, "</title>
  <style type=\"text/css\">
  body {
  font:normal 68% verdana,arial,helvetica;
  color:#000000;
  }
  table tr td, table tr th {
  font-size: 68%;
  }
  table.details tr th{
  font-weight: bold;
  text-align:left;
  background:#a6caf0;
  }
  table.details tr td{
  background:#eeeee0;
  white-space: nowrap;
  }
  h1 {
  margin: 0px 0px 5px; font: 165% verdana,arial,helvetica
  }
  h2 {
  margin-top: 1em; margin-bottom: 0.5em; font: bold 125% verdana,arial,helvetica
  }
  h3 {
  margin-bottom: 0.5em; font: bold 115% verdana,arial,helvetica
  }
  .Failure {
  font-weight:bold; color:red;
  }
  .collapsable1 {
  margin: 1em;
  padding: 1em;
  border: 1px solid black;
  }
  .collapsable {
  margin: 0em;
  padding: 0em;
  border: 0px solid white;
  }   				
  </style>
  <script type='text/javascript' src='collapse.js'></script>
  </head>
  <body>")

  writeLines(str, fo)
  if (heading1) {
    writeLines(concat("<h1>", title, "</h1>"), fo)
  }
  flush(fo)
}

html.footer = function(fo) {
  writeLines("</body></html>", fo)
  flush(fo)
}

html.td = function(str) {
  concat("<td>",str,"</td>")
}

html.table.row = function(...) {
  print("html.table.row: start")
  c1 = as.vector(c(...))
  print(c1)
  print(str(c1))
  print(length(c1))
  print("html.table.row: end")
  concat("<tr>", concat.list(sapply(c(...), html.td, USE.NAMES=FALSE)), 
         "</tr>")
}

html.table = function(df) {
  df2 = ddply(df, .(y), function(dfp) {
    c(tr = html.table.row(dfp$y, dfp$fac))
  })
  concat("<table>", concat.list(df2$tr), "</table>")
}

concat.list = function(l) {
  Reduce(function(res, str) {concat(res, str)}, l)
}

