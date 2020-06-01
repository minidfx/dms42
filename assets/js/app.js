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

// INFO: Because the message is sometimes received before than the element exists, we have to wait for the DOM to be updated and retry.
const waitForNode = (jQueryPath, callback, retry) => {
  const localRetry = retry || 0
  if (localRetry > maxRetry) {
    throw new Error(`Was not able to find the node after ${maxRetry}.`)
  }

  let htmlTag = $(jQueryPath)
  if (htmlTag.length < 1) {
    window.setTimeout(() => waitForNode(jQueryPath, callback, localRetry + 1), 10)
    return
  }

  callback(htmlTag)
}

app.ports.dropZone.subscribe(request => {
  const {
    jQueryPath,
    jQueryTagsPath
  } = request
  waitForNode(jQueryPath,
    x => {
      const localDropZone = x.dropzone({
        url: "/api/documents",
        params: (file) => {
          const localFile = file[0]
          return {
            tags: $(jQueryTagsPath)
              .select2('data')
              .map(x => x.text),
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
})
app.ports.tags.subscribe(request => {
  const {
    jQueryPath,
    documentId,
    tags,
    documentTags
  } = request
  const localTags = tags.sort()
    .map((x, i) => {
      return {
        id: i,
        text: x,
        selected: false
      }
    })
  const data = localTags.map(x => _.indexOf(documentTags, x.text) !== -1 ? _.set(x, 'selected', true) : x)

  waitForNode(jQueryPath,
    x => {
      const localControl = x.select2({
        tags: true,
        tokenSeparators: [',', ' '],
        minimumInputLength: 2,
        multiple: true,
        data: data
      })

      if (documentId) {
        localControl.on('select2:select', x => {
          app.ports.addTags.send({
            documentId: documentId,
            tags: [x.params.data.text]
          })
        })
        localControl.on('select2:unselect', x => {
          app.ports.removeTags.send({
            documentId: documentId,
            tags: [x.params.data.text]
          })
        })
      }
    })
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