module Routing exposing (..)

import Navigation exposing (Location)
import UrlParser exposing (..)


type Route
    = Home
    | AddDocuments
    | Document String
    | Documents
    | Settings


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map Home top
        , map AddDocuments (s "add-documents")
        , map Document (s "documents" </> string)
        , map Documents (s "documents")
        , map Settings (s "settings")
        ]


parseLocation : Location -> Route
parseLocation location =
    case (parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            Home
