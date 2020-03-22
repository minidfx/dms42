import css from '../css/app.css'

import 'dropzone/dist/min/dropzone.min.js'
import 'bootstrap4-tagsinput-douglasanpa/tagsinput.js'

const bodyTag = document.getElementsByTagName('body')
if (bodyTag) {
    const app = Elm.Main.embed(bodyTag[0])

    window.loadTokenFields = function (query, document_id) {
        const inputTokenFields = $(query)

        inputTokenFields.tagsinput(
            {
                trimValue: true
            })
        inputTokenFields.on("itemAdded", function (event) {
            const tag = event.item
            app.ports.newTag.send([tag, document_id])
        })
        inputTokenFields.on("itemRemoved", function (event) {
            const tag = event.item
            app.ports.deleteTag.send([tag, document_id])
        })
    }

    window.loadDropZone = function () {
        $("div.dropzone")
            .dropzone(
                {
                    url: "/api/documents",
                    params: function (file) {
                        var file = file[0];
                        return {
                            document_type: $("#documentType")
                                .val(),
                            tags: $("#tags")
                                .val(),
                            fileUnixTimestamp: file.lastModified
                        }
                    },
                    autoProcessQueue: true,
                    parallelUploads: 1000,
                    ignoreHiddenFiles: true,
                    acceptedFiles: "image/*,application/pdf"
                });
    };
}