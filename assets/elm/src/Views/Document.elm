module Views.Document exposing (..)

import Html exposing (Html, div, h1, text, input)
import Html.Attributes exposing (class, classList)
import Models.Application exposing (..)
import Routing exposing (DocumentId)


index : Models.Application.AppModel -> DocumentId -> Html Msg
index model documentId =
    div [] []
