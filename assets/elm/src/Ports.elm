port module Ports exposing (..)

import Models exposing (Tag)


port newTag : (( String, String ) -> msg) -> Sub msg


port deleteTag : (( String, String ) -> msg) -> Sub msg
