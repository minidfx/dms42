import '../css/app.css'

import $ from 'jquery'
import Dropzone from 'dropzone'
import 'typeahead.js'
import 'bootstrap4-tagsinput-douglasanpa/tagsinput.js'
import 'bootstrap/js/dist'
import 'bootstrap/dist/js/bootstrap.min.js'
import Bloodhound from 'typeahead.js/dist/bloodhound.min.js'
import '@fortawesome/fontawesome-free'

import '../images'

import Elm from '../elm/src/Main.elm'

// Disable auto discover for all elements:
Dropzone.autoDiscover = false

const app = Elm.Elm.Main.init({node: document.getElementsByName("body")})
const maxRetry = 10

// INFO: Because the message is sometimes received before than the element exists, we have to wait for the DOM to be updated and retry.
const waitForNode = (jQueryPath, callback, retry) => {
    if (retry > maxRetry) {
        throw new Error(`Was not able to find the node after ${maxRetry}.`)
    }

    let htmlTag = $(jQueryPath)
    if (htmlTag.length < 1) {
        window.setTimeout(() => waitForNode(jQueryPath, callback, retry + 1), 10)
        return
    }

    callback(htmlTag)
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
                parallelUploads: 50,
                ignoreHiddenFiles: true,
                acceptedFiles: "image/*,application/pdf"
            })[0].dropzone

            localDropZone.on('queuecomplete',
                () => {
                    app.ports.uploadCompleted.send(null)
                })
                .on('complete',
                    x => {
                        if (localDropZone.getAcceptedFiles().length < 1) {
                            return
                        }

                        window.setTimeout(() => {
                                if(x.status === "success") {
                                    localDropZone.removeFile(x)
                                }

                                // HACK: Not the best way because for each file the queue is processed.
                                localDropZone.processQueue()
                            },
                            3000)
                    })
        },
        0)
})
app.ports.tags.subscribe(request => {
    const {jQueryPath, documentId} = request

    waitForNode(jQueryPath,
        x => {
            const tags = new Bloodhound({
                datumTokenizer: Bloodhound.tokenizers.whitespace,
                queryTokenizer: Bloodhound.tokenizers.whitespace,
                // url points to a json file that contains an array of country names, see
                // https://github.com/twitter/typeahead.js/blob/gh-pages/data/countries.json
                prefetch: '/api/tags'
            })

            x.tagsinput(
                {
                    trimValue: true,
                    typeaheadjs: {
                        name: 'tags',
                        source: tags
                    }
                })

            if (documentId) {
                x
                    .on('itemRemoved', t => {
                        app.ports.removeTags.send({documentId: documentId, tags: [t.item]})
                    })
                    .on('itemAdded', t => {
                        app.ports.addTags.send({documentId: documentId, tags: [t.item]})
                    })
            }
        },
        0)
})
app.ports.clearCacheTags.subscribe(() => {
    window.localStorage.removeItem('__/api/tags__data')
})
app.ports.upload.subscribe(request => {
    const {jQueryPath, jQueryTagsPath} = request
    const localDropZone = $(jQueryPath)[0].dropzone
    const newFiles = localDropZone.files.filter(x => x.status !== "success")

    if (newFiles.length < 1) {
        app.ports.uploadCompleted.send(null)
        $(jQueryTagsPath).tagsinput('removeAll');
    }

    localDropZone.processQueue()
})