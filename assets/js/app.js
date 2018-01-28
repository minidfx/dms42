// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

const bodyTag = document.getElementsByTagName('body');
if (bodyTag)
{
  var app = Elm.Main.embed(bodyTag[0]);

  window.getUploadFields = function(file) {
    var file = file[0];
    return { document_type: $("select.form-control-document-type").val(),
             tags: $("input.form-control-tags").tokenfield("getTokens").map(x => x.value),
             fileUnixTimestamp: file.lastModified}
   };
}
