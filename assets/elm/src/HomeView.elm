module HomeView exposing (view)

import Html exposing (Html)
import Html.Attributes
import PageView
import Models


view : Models.AppState -> Html Models.Msg
view state =
    Html.div [ Html.Attributes.class "home-search" ]
        [ Html.div
            [ Html.Attributes.class "input-group mb-3" ]
            [ Html.input
                [ Html.Attributes.type_ "text"
                , Html.Attributes.class "form-control"
                ]
                []
            ]
        ]
