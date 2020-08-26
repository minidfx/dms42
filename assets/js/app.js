import "core-js/stable"
import "regenerator-runtime/runtime"

import '../css/app.less'

import $ from 'jquery'
import Dropzone from 'dropzone'
import 'bootstrap/js/dist'
import 'bootstrap/dist/js/bootstrap.min.js'
import '@fortawesome/fontawesome-free'
import 'select2/dist/js/select2.min.js'
import _ from 'lodash/lodash.min'

import Elm from '../elm/src/Main.elm'

// Disable auto discover for all elements:
Dropzone.autoDiscover = false

const app = Elm.Elm.Main.init({
    node: document.getElementsByName("body")
})
const maxRetry = 100

const sleepAsync = (milliseconds) => {
    let timeout
    return new Promise((resolve, _) => {
        timeout = setTimeout(resolve, milliseconds)
    })
        .finally(() => {
            if (timeout) {
                clearTimeout(timeout)
            }
        })
}

// INFO: Because the message is sometimes received before than the element exists, we have to wait for the DOM to be updated and retry.
const waitForNodeAsync = (jQueryPath, retry) => {
    return new Promise(async (resolve, reject) => {
        let localRetry = retry || 0

        while (localRetry <= maxRetry) {
            let htmlTag = $(jQueryPath)
            if (htmlTag.length > 0) {
                resolve(htmlTag)
                return
            }

            await sleepAsync(10)
            localRetry++
        }

        reject(new Error(`This is not an error with ELM! Was not able to find the node after ${maxRetry} retries.`))
    })
}

app.ports.dropZone.subscribe(async request => {
    const {
        jQueryPath,
        jQueryTagsPath
    } = request
    const node = await waitForNodeAsync(jQueryPath)
    const localDropZone = node.dropzone({
        url: "/api/documents",
        params: (file) => {
            const tags = $(jQueryTagsPath).select2('data').map(x => x.text).join(',') 
            console.debug(tags)
            const localFile = file[0]
            return {
                tags: tags,
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
            $(jQueryTagsPath)
                .val(null)
                .trigger('change')
        })
        .on('complete',
            x => {
                if (localDropZone.getAcceptedFiles()
                    .length < 1) {
                    return
                }

                window.setTimeout(() => {
                        if (x.status === "success") {
                            localDropZone.removeFile(x)
                        }

                        // HACK: Not the best way because for each file the queue is processed.
                        localDropZone.processQueue()
                    },
                    3000)
            })
})

app.ports.unloadTags.subscribe(async request => {
    const {
        jQueryPath
    } = request

    const node = await waitForNodeAsync(jQueryPath)
    if (!node.hasClass("select2-hidden-accessible")) {
        console.warn('The select2 was not loaded on the DOM element, skipping !')
        return
    }

    node.select2('close')
    node.select2('destroy')
})
app.ports.tags.subscribe(async request => {
    const {
        jQueryPath,
        documentId,
        tags,
        documentTags
    } = request
    const node = await waitForNodeAsync(jQueryPath)
    const localTags = tags.sort()
        .map((x, i) => {
            return {
                id: i,
                text: x,
                selected: false
            }
        })
    const data = localTags.map(x => _.indexOf(documentTags, x.text) !== -1 ? _.set(x, 'selected', true) : x)
    const localControl = node.select2({
        tags: true,
        tokenSeparators: [',', ' '],
        minimumInputLength: 2,
        multiple: true,
        data: data
    })

    if (documentId) {
        const handlerToAddTag = x => {
            app.ports.addTags.send({
                documentId: documentId,
                tags: [x.params.data.text]
            })
        }
        const handlerToRemoveTag = x => {
            app.ports.removeTags.send({
                documentId: documentId,
                tags: [x.params.data.text]
            })
        }

        localControl.on('select2:select', handlerToAddTag)
        localControl.on('select2:unselect', handlerToRemoveTag)
    }
})
app.ports.upload.subscribe(request => {
    const {
        jQueryPath,
        jQueryTagsPath
    } = request
    const localDropZone = $(jQueryPath)[0].dropzone
    const newFiles = localDropZone.files.filter(x => x.status !== 'success')

    if (newFiles.length < 1) {
        app.ports.uploadCompleted.send(null)
        $(jQueryTagsPath)
            .val(null)
            .trigger('change')
        return
    }

    localDropZone.processQueue()
})