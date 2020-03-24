import '../css/app.css'

import $ from 'jquery'
import Dropzone from 'dropzone'
import 'bootstrap4-tagsinput-douglasanpa/tagsinput.js'

import Elm from '../elm/src/Main.elm'

// Disable auto discover for all elements:
Dropzone.autoDiscover = false

const app = Elm.Elm.Main.init({node: document.getElementsByName("body")})

app.ports.dropZone.subscribe(function(jQueryPath) {
    $(jQueryPath).dropzone(
        {
            url: "/api/documents",
            params: function (file) {
                const localFile = file[0]
                return {
                    tags: $("#tags").val(),
                    fileUnixTimestamp: localFile.lastModified
                }
            },
            autoProcessQueue: true,
            parallelUploads: 1000,
            ignoreHiddenFiles: true,
            acceptedFiles: "image/*,application/pdf"
        });
});
app.ports.tags.subscribe(function(jQueryPath) {
    const inputTokenFields = $(jQueryPath)

    inputTokenFields.tagsinput(
        {
            trimValue: true
        })
    inputTokenFields.on("itemAdded", function (event) {
        const tag = event.item
        // app.ports.newTag.send([tag, document_id])
    })
    inputTokenFields.on("itemRemoved", function (event) {
        const tag = event.item
        // app.ports.deleteTag.send([tag, document_id])
    })
})