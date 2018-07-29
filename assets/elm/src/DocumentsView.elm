module DocumentsView exposing (view)

import Html exposing (Html)
import Html.Attributes
import Models
import Rfc2822Datetime
import Dict exposing (Dict)
import Bootstrap.Alert
import Bootstrap.Card
import Bootstrap.Card.Block
import Bootstrap.Pagination
import Bootstrap.General.HAlign
import Helpers
import SharedViews


documentsList : Models.AppState -> Html Models.Msg
documentsList state =
    let
        { documents, documentsCount, documentsLength } =
            state
    in
        case documents of
            Nothing ->
                Html.div [] [ Bootstrap.Alert.simpleWarning [] [ Html.text "No documents" ] ]

            Just d ->
                let
                    documentAsList =
                        Dict.values d |> List.take documentsLength

                    pagination =
                        Bootstrap.Pagination.defaultConfig
                            |> Bootstrap.Pagination.ariaLabel "documents-pagination"
                            |> Bootstrap.Pagination.itemsList (itemsList state)
                            |> Bootstrap.Pagination.align Bootstrap.General.HAlign.centerXs
                            |> Bootstrap.Pagination.view
                in
                    case documentAsList of
                        [] ->
                            Html.div [] [ Bootstrap.Alert.simpleWarning [] [ Html.text "No documents" ] ]

                        list ->
                            let
                                cards =
                                    case (>) documentsCount documentsLength of
                                        True ->
                                            Html.div []
                                                [ pagination
                                                , Html.div
                                                    [ Html.Attributes.class "row" ]
                                                    (List.map (\x -> SharedViews.card x) list)
                                                , pagination
                                                ]

                                        False ->
                                            Html.div
                                                [ Html.Attributes.class "row" ]
                                                (List.map (\x -> SharedViews.card x) list)
                            in
                                cards


itemsList : Models.AppState -> Bootstrap.Pagination.ListConfig Int Models.Msg
itemsList { documentsOffset, documentsLength, documentsCount } =
    { selectedMsg = Models.ChangeDocumentsPage
    , prevItem = Just <| Bootstrap.Pagination.ListItem [] [ Html.text "Previous" ]
    , nextItem = Just <| Bootstrap.Pagination.ListItem [] [ Html.text "Next" ]
    , activeIdx = (//) documentsOffset documentsLength
    , data = List.range 1 ((+) 1 <| (//) documentsCount documentsLength)
    , itemFn = \x _ -> Bootstrap.Pagination.ListItem [] [ Html.text <| toString <| (+) x 1 ]
    , urlFn = \x _ -> "#documents"
    }


view : Models.AppState -> Html Models.Msg
view state =
    let
        { documentsCount } =
            state
    in
        Html.div []
            [ Html.div [ Html.Attributes.class "row" ]
                [ Html.div [ Html.Attributes.class "col-md-6" ]
                    [ Html.span [ Html.Attributes.class "align-middle" ] [ Html.text <| "Documents: " ++ toString documentsCount ]
                    ]
                , Html.div [ Html.Attributes.class "col-md-6 text-right" ]
                    [ Html.a [ Html.Attributes.class "btn btn-primary", Html.Attributes.href "#add-documents" ] [ Html.text "Add" ]
                    ]
                ]
            , Html.hr [] []
            , documentsList state
            ]
