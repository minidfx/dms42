module Views.Documents exposing (..)

import Html exposing (Html, div, h1, text, input, img, p, h3, span, dl, dt, dd, a)
import Html.Attributes exposing (class, classList, src, alt, style, property, href)
import Html.Events exposing (onClick)
import Models exposing (AppState, Msg, Document)
import Formatting exposing (s, int, any, (<>), print)
import Rfc2822Datetime exposing (..)
import Json.Encode as Encode
import String exposing (padRight)
import Views.Common exposing (waitForItems)
import Dict exposing (Dict, toList, values)


index : AppState -> Html Msg
index model =
    let
        documents =
            case model.documents of
                Nothing ->
                    Nothing

                Just x ->
                    Just (Dict.values x)
    in
        div []
            [ div [ class "panel panel-default" ]
                [ div [ class "panel-body" ]
                    [ a [ href "#add-documents", class "btn btn-primary" ] [ text "Add documents" ]
                    ]
                ]
            , waitForItems documents documentBlocks
            ]


datetime : Datetime -> String
datetime datetime =
    print (int <> s " " <> any <> s " " <> int) datetime.date.day datetime.date.month datetime.date.year


propertyKey : String -> Html Msg
propertyKey value =
    dt [] [ text value ]


propertyValue : String -> Html Msg
propertyValue value =
    dd [] [ text value ]


thumbnailBlock : Document -> Html Msg
thumbnailBlock { comments, insertedAt, updatedAt, document_id } =
    a [ href ("#documents/" ++ document_id) ]
        [ div [ class "col-sm-4 col-md-2" ]
            [ div [ class "thumbnail" ]
                [ img [ alt "", src ("/documents/thumbnail/" ++ document_id) ] []
                , div [ class "caption" ]
                    [ div [ style [ ( "margin-left", "0" ) ] ]
                        [ dl []
                            [ propertyKey "Last update"
                            , propertyValue (datetime updatedAt)
                            ]
                        ]
                    ]
                ]
            ]
        ]


documentBlocks : List Document -> List (Html Msg) -> Html Msg
documentBlocks documents acc =
    case documents of
        [] ->
            div [ class "row" ] acc

        head :: tail ->
            documentBlocks tail ((thumbnailBlock head) :: acc)
