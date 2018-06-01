module Views.Common exposing (..)

import Html exposing (Html, text, div, img, a, node, span, nav, ul, li)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class, classList, src, style, attribute, type_, href)
import Models exposing (AppState, Msg, Msg(DidDocumentChangedPage, PagePrevious, PageNext))
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


pagination : AppState -> Int -> Html Msg
pagination state count =
    let
        pages =
            List.map (\x -> page state x) (List.range 0 (count - 1))

        { current_page } =
            state

        pageNextLink =
            if current_page == count + 1 then
                li [ class "disabled" ]
                    [ span [ attribute "aria-hidden" "true" ] [ text ">" ]
                    ]
            else
                li []
                    [ a [ onClick PageNext, style [ ( "cursor", "pointer" ) ] ] [ span [ attribute "aria-hidden" "true" ] [ text ">" ] ]
                    ]

        withNext =
            List.concat
                [ pages
                , [ pageNextLink
                  ]
                ]

        withPrevious =
            withNext
                |> List.append
                    [ li [ classList [ ( "disabled", current_page == 0 ) ] ]
                        [ a [ onClick PagePrevious, style [ ( "cursor", "pointer" ) ] ] [ span [ attribute "aria-hidden" "true" ] [ text "<" ] ]
                        ]
                    ]
    in
        nav []
            [ ul [ class "pagination" ]
                withPrevious
            ]


page : AppState -> Int -> Html Msg
page state index =
    let
        { current_page } =
            state
    in
        li [ classList [ ( "active", current_page == index ) ] ]
            [ a [ onClick (DidDocumentChangedPage index), style [ ( "cursor", "pointer" ) ] ] [ span [ attribute "aria-hidden" "false" ] [ text (toString (index + 1)) ] ]
            ]
