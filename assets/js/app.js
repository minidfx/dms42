// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

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
            var tag = event.item
            app.ports.newTag.send([tag, document_id])
        })
        inputTokenFields.on("itemRemoved", function (event) {
            var tag = event.item
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