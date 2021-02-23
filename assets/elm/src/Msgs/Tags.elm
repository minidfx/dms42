module Msgs.Tags exposing (..)

import Http
import Models exposing (UpdateTagRequest)


type Msg
    = Home
    | ToggleTag String
    | GotSearchResult (Result Http.Error (List Models.DocumentResponse))
    | CleanResult
    | UserTypeFilter String
    | Clear
    | OnInputEditTag String
    | OnKeyPressEditTag Int
    | EditTag String
    | UpdateTag UpdateTagRequest
    | DidUpdateTag (Result Http.Error Models.UpdateTagResponse)
    | DidRefreshTags
    | Nop
