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
  table.details td.count {
  text-align: right;
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

html.hr = function(fo) {
  writeLines("<hr align=\"left\" width=\"100%\" size=\"1\">", fo)
}

html.get.heading = function(level, text) {
  concat("<h", level, ">", text, "</h", level, ">")
}

html.heading = function(fo, level, text) {
  writeLines(html.get.heading(level, text), fo)
}

html.get.img = function(img_ref, extra="") {
  concat("<img src=\"", img_ref, "\"", extra, "/>")
}

html.img = function(fo, img_ref, ...) {
  writeLines(html.get.img(img_ref, ...), fo)
}

####################
# table functions  #
####################
html.td = function(str) {
  # experiment: gebruik ' voor 1000-sep.
  if (grepl("^-?[0-9.,']+$", str)) {
    concat("<td class='count'>",str,"</td>")  
  } else {
    concat("<td>",str,"</td>")
  }
}

html.th = function(str) {
  concat("<th>",str,"</th>")
}

html.table.row = function(...) {
  concat("<tr>", concat(sapply(list(...), html.td, USE.NAMES=FALSE), collapse="\n"), 
         "</tr>")
}

html.table.header.row = function(...) {
  concat("<tr>", concat(sapply(list(...), html.th, USE.NAMES=FALSE), collapse="\n"), 
         "</tr>")
}
