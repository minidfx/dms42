module Views.Settings exposing (view)

import Html exposing (Html)
import Models



-- Public members


view : Models.State -> List (Html Models.Msg)
view state =
    [ Html.text "The settings page" ]
