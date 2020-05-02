module Msgs.Documents exposing (..)

import Http
import Models


type Msg
    = Home
    | GotDocuments (Result Http.Error Models.DocumentsResponse)
    | Nop
