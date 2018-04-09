module Updates.Home

import Models exposing (Msg, Msg(DidDocumentFetched))
import Http

fetchDocuments : String -> Cmd Msg
fetchDocuments criteria =
    Http.send DidDocumentFetched <| Http.post "http://localhost:4000/api/documents/search"
