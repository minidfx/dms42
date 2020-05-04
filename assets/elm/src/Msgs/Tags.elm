module Msgs.Tags exposing (..)

import Http
import Models


type Msg
    = Home
    | ToggleTag String
    | GotSearchResult (Result Http.Error (List Models.DocumentResponse))
    | CleanResult
    | Nop
