port module Ports.Document exposing (createToken, deleteToken, notifyAddToken, notifyRemoveToken)

import Models exposing (Tag)


port notifyAddToken : String -> Cmd msg


port notifyRemoveToken : String -> Cmd msg


port createToken : (( String, String ) -> msg) -> Sub msg


port deleteToken : (( String, String ) -> msg) -> Sub msg
