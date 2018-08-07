module DocumentsView exposing (view)

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Models
import Rfc2822Datetime
import Dict exposing (Dict)
import Bootstrap.Alert
import Bootstrap.Card
import Bootstrap.Card.Block
import Bootstrap.Pagination
import Bootstrap.Pagination.Item
import Bootstrap.General.HAlign
import Helpers
import SharedViews
import Debug


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
                        Dict.values d
                            |> List.sortBy (\{ datetimes } -> datetimes.inserted_datetime |> Helpers.dateTimeToString)
                            |> List.reverse
                            |> List.take documentsLength

                    pagination =
                        Bootstrap.Pagination.defaultConfig
                            |> Bootstrap.Pagination.ariaLabel "documents-pagination"
                            |> Bootstrap.Pagination.items (paginationItems state)
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


paginationItem : List (Html Models.Msg) -> Int -> Bool -> Bool -> Bootstrap.Pagination.Item.Item Models.Msg
paginationItem content index isActive isDisabled =
    Bootstrap.Pagination.Item.item
        |> Bootstrap.Pagination.Item.active isActive
        |> Bootstrap.Pagination.Item.disabled isDisabled
        |> Bootstrap.Pagination.Item.link
            [ Html.Attributes.href "#documents"
            , Html.Attributes.class "custom-page-item"
            , Html.Events.onClick (Models.ChangeDocumentsPage index)
            ]
            content


paginationItems : Models.AppState -> List (Bootstrap.Pagination.Item.Item Models.Msg)
paginationItems { documentsOffset, documentsLength, documentsCount } =
    let
        maxPages =
            10

        currentPage =
            Debug.log "current" <|
                (//) documentsOffset documentsLength

        pages =
            Debug.log "pages" <|
                (//) documentsCount documentsLength

        padding =
            4

        previous =
            paginationItem
                [ Html.span
                    [ Html.Attributes.class "fa fa-backward"
                    , Html.Attributes.attribute "aria-hidden" "true"
                    ]
                    []
                , Html.span [ Html.Attributes.class "sr-only" ]
                    [ Html.text "Previous" ]
                ]
                ((-) currentPage 1)
                False
                ((==) currentPage 0)

        next =
            paginationItem
                [ Html.span
                    [ Html.Attributes.class "fa fa-forward"
                    , Html.Attributes.attribute "aria-hidden" "true"
                    ]
                    []
                , Html.span [ Html.Attributes.class "sr-only" ]
                    [ Html.text "Next" ]
                ]
                ((+) currentPage 1)
                False
                ((==) currentPage pages)

        dotButton =
            paginationItem
                [ Html.span []
                    [ Html.text "..." ]
                ]
                0
                False
                True

        localMin =
            Debug.log "min" <|
                Basics.max 0 <|
                    (-) currentPage padding

        localMax =
            Debug.log "max" <|
                Basics.min pages <|
                    (+) currentPage padding

        firstPart =
            case (>) ((-) currentPage padding) 0 of
                True ->
                    [ previous, dotButton ]

                False ->
                    [ previous ]

        lastPart =
            case (>) ((-) pages padding) currentPage of
                True ->
                    [ dotButton, next ]

                False ->
                    [ next ]
    in
        firstPart
            ++ (List.range localMin localMax
                    |> List.map
                        (\x ->
                            paginationItem [ Html.text <| toString <| (+) x 1 ]
                                x
                                ((==) x currentPage)
                                False
                        )
               )
            ++ lastPart


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
