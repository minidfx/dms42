module Routing exposing (..)

import Navigation exposing (Location)
import UrlParser exposing (..)


type alias DocumentId =
    Int


type Route
    = Home
    | AddDocuments
    | Document DocumentId
    | Documents
    | Settings


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map Home top
        , map AddDocuments (s "add-documents")
        , map Document (s "documents" </> int)
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
