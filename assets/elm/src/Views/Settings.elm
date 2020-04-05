module Views.Settings exposing (view)

import Html exposing (Html)
import Html.Attributes
import Models



-- Public members


view : Models.State -> List (Html Models.Msg)
view state =
    [ Html.div [ Html.Attributes.class "d-flex empty" ]
        [ Html.div [ Html.Attributes.class "mr-auto ml-auto" ]
            [ Html.i
                [ Html.Attributes.class "fas fa-otter"
                , Html.Attributes.title "No documents"
                ]
                []
            ]
        ]
    ]
