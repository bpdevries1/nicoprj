function deleteImages() {
  // alert("deleteImages: start");
  var selectedInputs = $("input:checked");
  var selectedIds = [];
  selectedInputs
    .each(function() {
       selectedIds.push($(this).attr('id'))
    });
  if (selectedIds.length < 1) alert("no images selected");
  else
    $.post(context + "/delete",
           {names: selectedIds},
          function(response) {
            var errors = $('<ul>');
            $.each(response, function() {
              if("ok" === this.status) {
                var element = document.getElementById(this.name);
                // $(element).parent().parent().remove();
                $(element).parent().remove();
              }
              else
                errors
                .append($('<li>',
                          {html: "failed to remove " +
                                  this.name +
                                  ": " +
                                  this.status}));
            });
            if (errors.length > 0)
              $('#error').empty().append(errors); // empty altijd doen, als errors van vorige keer weg moeten?
            },
            "json");
};

$(document).ready(function() {
  // alert("doc ready: start");
  $("#delete").click(deleteImages);
});
