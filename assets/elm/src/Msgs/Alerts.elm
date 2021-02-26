module Msgs.Alerts exposing (..)

import Models


type Msg
    = Close Int
    | Publish Models.AlertRequest
    | Nop
