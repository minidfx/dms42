module Views.Common exposing (..)

import Html exposing (Html, text, div, img, a, node)
import Html.Attributes exposing (class, src, style, attribute, type_)
import Models exposing (Msg)
import Rfc2822Datetime exposing (Datetime)


rfc2822String : Rfc2822Datetime.Datetime -> String
rfc2822String { date, time } =
    let
        { year, month, day } =
            date

        { hour, minute } =
            time
    in
        toString year ++ " " ++ toString month ++ " " ++ toString day ++ ", " ++ toString hour ++ ":" ++ toString minute


script : String -> Html Msg
script code =
    node "script" [ type_ "text/javascript" ] [ text code ]


waitForItems : Maybe (List any) -> (List any -> List (Html Msg) -> Html Msg) -> Html Msg
waitForItems items function =
    case items of
        Nothing ->
            div [ class "row" ]
                [ div [ class "col-md-12 text-center" ]
                    [ img [ src "/images/spinner.gif", style [ ( "width", "200px" ) ] ] []
                    ]
                ]

        Just x ->
            case x of
                [] ->
                    div [ class "alert alert-info", attribute "role" "alert" ]
                        [ text "No items"
                        ]

                x ->
                    function x []
