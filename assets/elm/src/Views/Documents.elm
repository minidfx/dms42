module Views.Documents exposing (..)

import Html exposing (Html, div, h1, text, input, img, p, h3, span, dl, dt, dd, a)
import Html.Attributes exposing (class, classList, src, alt, style, property, href)
import Models.Application exposing (..)
import Formatting exposing (s, int, any, (<>), print)
import Rfc2822Datetime exposing (..)
import Json.Encode as Encode
import String exposing (padRight)


index : Models.Application.AppModel -> Html Msg
index model =
    div []
        [ div [ class "panel panel-default" ]
            [ div [ class "panel-body" ]
                [ a [ href "#add-documents", class "btn btn-primary" ] [ text "Add documents" ]
                ]
            ]
        , transtormToRow (List.reverse model.documents) []
        ]


fakeImage : String
fakeImage =
    "data:image/png;base64,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"


datetime : Datetime -> String
datetime datetime =
    print (int <> s " " <> any <> s " " <> int) datetime.date.day datetime.date.month datetime.date.year


propertyKey : String -> Html Msg
propertyKey value =
    dt [] [ text value ]


propertyValue : String -> Html Msg
propertyValue value =
    dd [] [ text value ]


transformDocument : Document -> Html Msg
transformDocument { comments, insertedAt, updatedAt, document_id } =
    div [ class "col-sm-4 col-md-2" ]
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


transtormToRow : List Document -> List (Html Msg) -> Html Msg
transtormToRow documents acc =
    case documents of
        [] ->
            div [ class "row" ] acc

        head :: tail ->
            transtormToRow tail ((transformDocument head) :: acc)
