module Shared exposing (..)

import Bootstrap.Card
import Html exposing (Html)
import Html.Attributes
import Models



-- Public members


card : Models.Document -> Html Models.Msg
card { datetimes, id } =
    let
        { inserted_datetime, updated_datetime } =
            datetimes
    in
    Html.div [ Html.Attributes.class "col-md-2" ]
        [ Html.a [ Html.Attributes.href ("#documents/" ++ id) ]
            [ Bootstrap.Card.config
                [ Bootstrap.Card.outlineInfo
                , Bootstrap.Card.attrs [ Html.Attributes.style "margin-bottom" "10px" ]
                ]
                |> Bootstrap.Card.footer [ Html.Attributes.class "text-center" ] [ Html.text "insert datetime" ]
                |> Bootstrap.Card.imgTop
                    [ Html.Attributes.src ("/documents/thumbnail/" ++ id)
                    , Html.Attributes.alt ("image-" ++ id)
                    ]
                    []
                |> Bootstrap.Card.view
            ]
        ]
