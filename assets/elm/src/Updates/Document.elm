module Updates.Document exposing (updateDocument)

import Models exposing (AppState, Msg)
import Json.Encode
import Http exposing (request, getString)


updateDocument : AppState -> Json.Encode.Value -> AppState
updateDocument model json =
    model
