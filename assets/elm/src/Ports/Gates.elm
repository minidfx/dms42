port module Ports.Gates exposing (..)

import Ports.Models


port dropZone : Ports.Models.DropZoneRequest -> Cmd msg


port tags : Ports.Models.TagsRequest -> Cmd msg


port upload : Ports.Models.UploadRequest -> Cmd msg


port uploadCompleted : (() -> msg) -> Sub msg


port addTags : (Ports.Models.TagsAdded -> msg) -> Sub msg


port removeTags : (Ports.Models.TagsRemoved -> msg) -> Sub msg
