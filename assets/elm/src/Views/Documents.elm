module Views.Documents exposing (..)

import Html exposing (Html, div, h1, text, input)
import Html.Attributes exposing (class, classList)
import Models.Application exposing (..)


index : Models.Application.AppModel -> Html msg
index model =
    div [] []
