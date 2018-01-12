module Models.Application exposing (..)

import Routing exposing (Route)


type Msg
    = None


type alias AppModel =
    { route : Route
    }


initialModel : Route -> AppModel
initialModel route =
    { route = route }
