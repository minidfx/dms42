module Routing exposing (..)

import Navigation exposing (Location)
import UrlParser exposing (..)


type alias DocumentId =
    Int


type Route
    = Home
    | Document DocumentId
    | Documents
    | None


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map Home top
        , map Document (s "documents" </> int)
        , map Documents (s "documents")
        ]


parseLocation : Location -> Route
parseLocation location =
    case (parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            None
