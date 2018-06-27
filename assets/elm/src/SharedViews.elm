module SharedViews exposing (..)

import Html exposing (Html)
import Html.Attributes
import Bootstrap.Card
import Bootstrap.Card.Block
import Helpers
import Models


card : Models.Document -> Html Models.Msg
card { datetimes, document_id } =
    let
        { inserted_datetime, updated_datetime } =
            datetimes
    in
        Html.div [ Html.Attributes.class "col-md-2" ]
            [ Html.a [ Html.Attributes.href ("#documents/" ++ document_id) ]
                [ Bootstrap.Card.config
                    [ Bootstrap.Card.outlineInfo
                    , Bootstrap.Card.attrs [ Html.Attributes.style [ ( "margin-bottom", "10px" ) ] ]
                    ]
                    |> Bootstrap.Card.footer [ Html.Attributes.class "text-center" ] [ Html.text (Helpers.dateTimeToString inserted_datetime) ]
                    |> Bootstrap.Card.imgTop
                        [ Html.Attributes.src ("/documents/thumbnail/" ++ document_id)
                        , Html.Attributes.alt ("image-" ++ document_id)
                        ]
                        []
                    |> Bootstrap.Card.view
                ]
            ]
