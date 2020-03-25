module Settings exposing (..)

import Html exposing (Html)
import Models


view : Models.State -> Html Models.Msg
view state =
    Html.text "The settings page"
