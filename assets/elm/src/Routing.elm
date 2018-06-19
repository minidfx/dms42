module Routing exposing (..)

import Navigation
import UrlParser exposing ((</>))


type alias DocumentId =
    String


type Route
    = Home
    | AddDocuments
    | Document DocumentId
    | DocumentProperties DocumentId
    | Documents
    | Settings


matchers : UrlParser.Parser (Route -> a) a
matchers =
    UrlParser.oneOf
        [ UrlParser.map Home UrlParser.top
        , UrlParser.map AddDocuments (UrlParser.s "add-documents")
        , UrlParser.map Document (UrlParser.s "documents" </> UrlParser.string)
        , UrlParser.map DocumentProperties (UrlParser.s "documents" </> UrlParser.string </> UrlParser.s "properties")
        , UrlParser.map Documents (UrlParser.s "documents")
        , UrlParser.map Settings (UrlParser.s "settings")
        ]


parseLocation : Navigation.Location -> Route
parseLocation location =
    case (UrlParser.parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            Home
