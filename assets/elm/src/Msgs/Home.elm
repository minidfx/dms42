module Msgs.Home exposing (..)

import Debounce
import Http
import Models


type Msg
    = Home
    | UserTypeSearch String
    | ThrottleSearchDocuments Debounce.Msg
    | GotSearchResult (Result Http.Error (List Models.DocumentResponse))
    | Clear
    | Nop
