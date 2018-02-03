module Views.Document exposing (..)

import Html exposing (Html, div, h1, text, input)
import Html.Attributes exposing (class, classList)
import Models exposing (AppState, Msg)


index : AppState -> String -> Html Msg
index model json =
    div [] []
