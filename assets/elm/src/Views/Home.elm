module Views.Home exposing (..)

import Html exposing (Html, div, h1, text, input)
import Html.Attributes exposing (class, classList, style, value, attribute)
import Models exposing (AppState, Msg, Msg(DidSearchKeyPressed))
import Html.Events exposing (onInput)
import Views.Documents as Documents
import Dict exposing (Dict, toList, values)


index : AppState -> Html Msg
index model =
    let
        { searchDocumentsResult, searchQuery } =
            model

        query =
            case searchQuery of
                Just x ->
                    x

                Nothing ->
                    ""

        documents =
            case searchDocumentsResult of
                Nothing ->
                    Nothing

                Just x ->
                    Just (Dict.values x)
    in
        div [ class "jumbotron" ]
            [ h1 [] [ text "Search" ]
            , div [ class "row" ]
                [ div [ classList [ ( "col-md-10", True ), ( "col-md-offset-1", True ) ] ]
                    [ input [ class "form-control", value query, onInput DidSearchKeyPressed ] []
                    ]
                ]
            , div [ class "row", style [ ( "margin-top", "20px" ) ] ]
                [ displaySearchResult documents Documents.documentBlocks
                ]
            ]


displaySearchResult : Maybe (List any) -> (List any -> List (Html Msg) -> Html Msg) -> Html Msg
displaySearchResult items function =
    case items of
        Nothing ->
            div [] []

        Just x ->
            case x of
                [] ->
                    div [ class "alert alert-info", attribute "role" "alert" ]
                        [ text "No result"
                        ]

                x ->
                    function x []
