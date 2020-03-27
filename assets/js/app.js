import '../css/app.css'

import $ from 'jquery'
import Dropzone from 'dropzone'
import 'bootstrap4-tagsinput-douglasanpa/tagsinput.js'
import 'typeahead.js/dist/typeahead.jquery.min.js'
import '@fortawesome/fontawesome-free'

import Elm from '../elm/src/Main.elm'

// Disable auto discover for all elements:
Dropzone.autoDiscover = false

const app = Elm.Elm.Main.init({node: document.getElementsByName("body")})

// INFO: Because the message is sometimes received before than the element exists, we have to wait for the DOM to be updated and retry.
const waitForNode = (jQueryPath, callback) => {
    let htmlTag = $(jQueryPath)
    if (htmlTag.length < 1) {
        window.setTimeout(() => waitForNode(jQueryPath, callback), 10)
        return
    }
    
    callback(htmlTag)
}

const substringMatcher = strings => {
    return (q, cb) => {
        let matches, substringRegex

        // an array that will be populated with substring matches
        matches = []

        // regex used to determine if a string contains the substring `q`
        substringRegex = new RegExp(q, 'i')

        // iterate through the pool of strings and for any string that
        // contains the substring `q`, add it to the `matches` array
        $.each(strings, function (i, str) {
            if (substringRegex.test(str)) {
                matches.push(str)
            }
        })
        
        cb(matches)
    }
}

app.ports.dropZone.subscribe(request => {
    const {jQueryPath, jQueryTagsPath} = request
    waitForNode(jQueryPath,
        x => {
            const localDropZone = x.dropzone({
                url: "/api/documents",
                params: (file) => {
                    const localFile = file[0]
                    return {
                        tags: $(jQueryTagsPath).val(),
                        fileUnixTimestamp: localFile.lastModified
                    }
                },
                autoProcessQueue: false,
                parallelUploads: 5,
                ignoreHiddenFiles: true,
                acceptedFiles: "image/*,application/pdf"
            })[0].dropzone

            localDropZone.on('queuecomplete',
                () => {
                    app.ports.uploadCompleted.send(null)
                })
                .on('complete',
                    x => {
                        if (x.status !== 'success') {
                            return
                        }

                        window.setTimeout(() => {
                                localDropZone.removeFile(x)

                                // HACK: Not the best way because for each file the queue is processed.
                                localDropZone.processQueue()
                            },
                            3000)
                    })
        })
})
app.ports.tags.subscribe(request => {
    const {jQueryPath, existingTags} = request
    waitForNode(jQueryPath,
        x => {
            x.tagsinput(
                {
                    trimValue: true,
                    typeaheadjs: {
                        name: 'existingTags',
                        source: substringMatcher(existingTags)
                    }
                })
        })
})
app.ports.upload.subscribe(request => {
    const {jQueryPath, jQueryTagsPath} = request
    const localDropZone = $(jQueryPath)[0].dropzone
    const newFiles = localDropZone.files.filter(x => x.status !== "success")

    if (newFiles.length < 1) {
        app.ports.uploadCompleted.send(null)
    }

    localDropZone.processQueue()
    $(jQueryTagsPath).tagsinput('removeAll');
})