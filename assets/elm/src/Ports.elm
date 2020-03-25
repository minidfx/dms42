port module Ports exposing (..)

import Models


port dropZone : Models.DropZoneRequest -> Cmd msg


port tags : Models.TagsRequest -> Cmd msg


port upload : Models.UploadRequest -> Cmd msg


port uploadCompleted : (() -> msg) -> Sub msg
