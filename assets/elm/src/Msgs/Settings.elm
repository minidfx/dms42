module Msgs.Settings exposing (..)

import Http
import Models


type Msg
    = Home
    | GotQueueInfo (Result Http.Error Models.QueueInfoResponse)
    | Nop
