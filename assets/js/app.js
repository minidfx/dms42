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

const bodyTag = document.getElementsByTagName('body')
if (bodyTag)
{
  var app = Elm.Main.embed(bodyTag[0])

  window.loadDropZone = function() {
    $("div.dropzone")
      .dropzone(
      {
        url: "/api/documents",
        params: function(file)
        {
          var file = file[0];
          return { document_type: $("#documentType").val(),
                   tags: [],
                   fileUnixTimestamp: file.lastModified }
        },
        autoProcessQueue: true,
        parallelUploads: 1000,
        ignoreHiddenFiles: true,
        acceptedFiles: "image/*,application/pdf"
      });
  };

  window.loadTokensFields = function(query, document_id, tags)
  {
    var inputTokenFields = $(query)

    inputTokenFields.tokenfield()

    if (tags !== undefined)
    {
      inputTokenFields.tokenfield("setTokens", tags)
      inputTokenFields.on('tokenfield:createtoken', function(e)
        {
          var tag = e.attrs.value
          app.ports.createToken.send([document_id, tag])
        })
        .on('tokenfield:removedtoken', function(e)
        {
          var tag = e.attrs.value
          app.ports.deleteToken.send([document_id, tag])
        })
    }
  }
}
