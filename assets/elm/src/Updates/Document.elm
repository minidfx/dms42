module Updates.Document exposing (updateDocument)

import Models exposing (AppState, Msg)
import Json.Encode


updateDocument : AppState -> Json.Encode.Value -> AppState
updateDocument model document_id =
    model
