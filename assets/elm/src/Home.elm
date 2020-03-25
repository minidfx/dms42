module Home exposing (..)

import Html exposing (Html)
import Html.Attributes
import Models


view : Models.State -> Html Models.Msg
view state =
    Html.div [ Html.Attributes.class "home-search" ]
        [ Html.div
            [ Html.Attributes.class "input-group mb-3" ]
            [ Html.input
                [ Html.Attributes.type_ "text"
                , Html.Attributes.class "form-control"
                ]
                []
            , Html.div [ Html.Attributes.class "input-group-append" ]
                [ Html.span [ Html.Attributes.class "input-group-text" ]
                    [ Html.i [ Html.Attributes.class "fas fa-search" ] []
                    ]
                ]
            ]
        ]
