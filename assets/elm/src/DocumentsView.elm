module DocumentsView exposing (view)

import Html exposing (Html)
import Html.Attributes
import Models
import Rfc2822Datetime
import Dict exposing (Dict)
import Bootstrap.Alert
import Bootstrap.Card
import Bootstrap.Card.Block


dateTimeToString : Rfc2822Datetime.Datetime -> String
dateTimeToString { date, time } =
    let
        { day, month, year } =
            date

        { hour, minute } =
            time
    in
        (toString day) ++ " " ++ (toString month) ++ " " ++ (toString year) ++ " " ++ (toString hour) ++ ":" ++ (toString minute)


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
                    |> Bootstrap.Card.footer [ Html.Attributes.class "text-center" ] [ Html.text (dateTimeToString inserted_datetime) ]
                    |> Bootstrap.Card.imgTop
                        [ Html.Attributes.src ("/documents/thumbnail/" ++ document_id)
                        , Html.Attributes.alt ("image-" ++ document_id)
                        ]
                        []
                    |> Bootstrap.Card.view
                ]
            ]


documentsList : Maybe (Dict String Models.Document) -> Html Models.Msg
documentsList documents =
    case documents of
        Nothing ->
            Html.div [] [ Bootstrap.Alert.simpleWarning [] [ Html.text "No documents" ] ]

        Just d ->
            let
                documentAsList =
                    Dict.values d
            in
                case documentAsList of
                    [] ->
                        Html.div [] [ Bootstrap.Alert.simpleWarning [] [ Html.text "No documents" ] ]

                    list ->
                        Html.div [ Html.Attributes.class "row" ] (List.map (\x -> card x) list)


view : Models.AppState -> Html Models.Msg
view { documents } =
    Html.div []
        [ Html.ul [ Html.Attributes.class "nav justify-content-center" ]
            [ Html.li [ Html.Attributes.class "nav-item" ]
                [ Html.a [ Html.Attributes.class "nav-link", Html.Attributes.href "#add-documents" ] [ Html.text "Add" ]
                ]
            ]
        , Html.hr [] []
        , documentsList documents
        ]
