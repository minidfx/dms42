module Settings exposing (view)

import Html exposing (Html)
import Models



-- Public members


view : Models.State -> Html Models.Msg
view state =
    Html.text "The settings page"
