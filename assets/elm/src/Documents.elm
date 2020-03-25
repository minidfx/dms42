module Documents exposing (..)

import Html exposing (Html)
import Html.Attributes
import Models


view : Models.State -> Html Models.Msg
view { documents } =
    let
        count =
            case documents of
                Just x ->
                    List.length x

                Nothing ->
                    0
    in
    Html.div []
        [ Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col-md-6" ]
                [ Html.span
                    [ Html.Attributes.class "documents align-middle" ]
                    [ Html.text <| String.fromInt count
                    , Html.i
                        [ Html.Attributes.class "fa fa-file highlight"
                        , Html.Attributes.title "Documents"
                        ]
                        []
                    ]
                ]
            , Html.div [ Html.Attributes.class "col-md-6 d-flex" ]
                [ Html.a
                    [ Html.Attributes.class "btn btn-primary ml-auto"
                    , Html.Attributes.href "/documents/add"
                    , Html.Attributes.title "Add documents"
                    ]
                    [ Html.i [ Html.Attributes.class "fa fa-plus" ] [] ]
                ]
            ]
        , Html.hr [ Html.Attributes.style "margin-top" "0.3em" ] []
        ]
