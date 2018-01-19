module Models.Application exposing (..)

import Routing exposing (Route)
import Rfc2822Datetime exposing (..)
import Formatting exposing (..)


type Msg
    = None


type alias Document =
    { name : String
    , thumbnailPath : String
    , creationDateTime : Datetime
    , lastUpdateDateTime : Datetime
    , comments : String
    }


type alias AppModel =
    { route : Route
    , documents : List Document
    }


createFakeDocument : Int -> Document
createFakeDocument index =
    { name = print (s "Document " <> int) index
    , thumbnailPath = ""
    , creationDateTime =
        { dayOfWeek = Just Mon
        , date =
            { year = 2017
            , month = Jan
            , day = 1
            }
        , time =
            { hour = 0
            , minute = 0
            , second = Just 1
            , zone = Offset 0
            }
        }
    , lastUpdateDateTime =
        { dayOfWeek = Just Mon
        , date =
            { year = 2017
            , month = Jan
            , day = 1
            }
        , time =
            { hour = 0
            , minute = 0
            , second = Just 1
            , zone = Offset 0
            }
        }
    , comments = "Officia aute sint esse ipsum consectetur incididunt ex enim occaecat magna fugiat."
    }


initialModel : Route -> AppModel
initialModel route =
    { route = route
    , documents =
        [ createFakeDocument 1
        , createFakeDocument 2
        , createFakeDocument 3
        , createFakeDocument 4
        , createFakeDocument 5
        , createFakeDocument 6
        ]
    }
