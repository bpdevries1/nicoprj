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

html.td2 = function(val) {
  # print(val)
  # experiment: gebruik ' voor 1000-sep.
  if (is.numeric(val)) {
    concat("<td class='count'>",f1000(val),"</td>")  
  } else {
    concat("<td>",val,"</td>")
  }
}

html.th = function(str) {
  concat("<th>",str,"</th>")
}

html.table.row = function(...) {
  concat("<tr>", concat(sapply(list(...), html.td, USE.NAMES=FALSE), collapse="\n"), 
         "</tr>")
}

html.table.row2 = function(df) {
  concat("<tr>", concat(sapply(df, html.td2, USE.NAMES=FALSE), collapse="\n"), 
         "</tr>")
}


html.table.header.row = function(...) {
  concat("<tr>", concat(sapply(list(...), html.th, USE.NAMES=FALSE), collapse="\n"), 
         "</tr>")
}

html.table.header.row2 = function(df) {
  concat("<tr>", concat(sapply(colnames(df), html.th, USE.NAMES=FALSE), collapse="\n"), 
         "</tr>")
}

# TODO shouldn't have to give idfield as param. table should be handled as-is by ddply behandeld worden, each row becomes a html table row.
write.html.table = function(fo, df, idfield) {
  df2 = ddply(df, as.quoted(idfield), function(dfp) {
    dfp1 = dfp[1,] # only need first record of dataframe: per useraction_id only one record exists.
    c(tr=html.table.row2(dfp1))
  })
  writeLines(concat("<table cellspacing=\"2\" cellpadding=\"5\" border=\"0\" class=\"details\">", 
                    html.table.header.row2(df),
                    concat(df2$tr, collapse="\n"), 
                    "</table>"), fo)
}

######################
# generic formatting #
######################

# integer: format with ' a 1000 separator
# numeric: use sprintf to always have 3 decimals, but no thousand separator.
f1000 = function(val) {
  # format(round(val, digits=3), big.mark="'", scientific=FALSE)
  # print(val)
  valn = as.numeric(val)
  # format(round(as.numeric(val), digits=3), big.mark="'", scientific=FALSE)
  # format(round(valn, digits=3), big.mark="'", scientific=FALSE)
  if (is.integer(val)) {
    # sprintf("%d", val)  
    format(round(valn, digits=3), big.mark="'", scientific=FALSE)
  } else {
    sprintf("%.3f", val)
  }
  
}

f1000.old = function(val) {
  # format(round(val, digits=3), big.mark="'", scientific=FALSE)
  # print(val)
  valn = as.numeric(val)
  # format(round(as.numeric(val), digits=3), big.mark="'", scientific=FALSE)
  format(round(valn, digits=3), big.mark="'", scientific=FALSE)
}
