module Msgs.Document exposing (..)

import Http
import Models
import Ports.Models


type Msg
    = Home
    | ShowDocumentAsModal
    | DeleteDocument String
    | DidDeleteDocument (Result Http.Error Models.DidDeleteDocumentResponse)
    | RunOcr Models.DocumentResponse
    | RunUpdateThumbnails Models.DocumentResponse
    | RunUpdateAll Models.DocumentResponse
    | DidRunOcr (Result Http.Error ())
    | DidRunUpdateThumbnails (Result Http.Error ())
    | AddTags Ports.Models.TagsAdded
    | RemoveTags Ports.Models.TagsRemoved
    | DidRemoveTags (Result Http.Error ())
    | DidAddTags (Result Http.Error ())
    | GotDocument (Result Http.Error Models.DocumentResponse)
