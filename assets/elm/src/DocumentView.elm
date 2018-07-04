module DocumentView exposing (..)

import Html exposing (Html)
import Html.Attributes
import Html.Events
import List
import Models
import Routing
import Helpers
import Bootstrap.Alert
import Bootstrap.ButtonGroup
import Bootstrap.Button
import Bootstrap.Form.Textarea
import Bootstrap.Modal
import Bootstrap.Pagination
import Bootstrap.General.HAlign


view : Models.AppState -> String -> Html Models.Msg
view state documentId =
    let
        document =
            Helpers.getDocument state documentId
    in
        case document of
            Nothing ->
                documentNotFound state documentId

            Just x ->
                documentDetails state x


confirmDelete : Models.AppState -> Models.Document -> Html Models.Msg
confirmDelete { modalState } { original_file_name, document_id } =
    Bootstrap.Modal.config Models.CloseModal
        |> Bootstrap.Modal.large
        |> Bootstrap.Modal.h5 []
            [ Html.text ("You are about to delete the document \"" ++ original_file_name ++ "\".")
            , Html.br [] []
            , Html.br [] []
            , Html.text "Are you sure?"
            ]
        |> Bootstrap.Modal.footer []
            [ Bootstrap.Button.button
                [ Bootstrap.Button.outlinePrimary
                , Bootstrap.Button.attrs [ Html.Events.onClick Models.CloseModal ]
                ]
                [ Html.text "Close" ]
            , Bootstrap.Button.button
                [ Bootstrap.Button.outlineDanger
                , Bootstrap.Button.onClick (Models.DeleteDocument document_id)
                ]
                [ Html.text "Delete" ]
            ]
        |> Bootstrap.Modal.view modalState


pageItem : Models.Document -> Int -> String -> Html Models.Msg
pageItem { document_id, thumbnails } page label =
    let
        currentImage =
            Helpers.safeValue thumbnails.currentImage 0
    in
        Html.li
            [ Html.Attributes.class "page-item"
            , Html.Attributes.classList [ ( "active", (==) currentImage page ) ]
            ]
            [ Html.a
                [ Html.Attributes.class "page-link"
                , Html.Events.onClick (Models.ChangeDocumentPage document_id page)
                ]
                [ Html.text label ]
            ]


itemsList : Models.Document -> Bootstrap.Pagination.ListConfig Int Models.Msg
itemsList { document_id, thumbnails } =
    let
        { countImages, currentImage } =
            thumbnails
    in
        { selectedMsg = \x -> Models.ChangeDocumentPage document_id x
        , prevItem = Just <| Bootstrap.Pagination.ListItem [] [ Html.text "Previous" ]
        , nextItem = Just <| Bootstrap.Pagination.ListItem [] [ Html.text "Next" ]
        , activeIdx = Helpers.safeValue currentImage 0
        , data = List.range 1 countImages
        , itemFn = \x _ -> Bootstrap.Pagination.ListItem [] [ Html.text <| toString <| (+) x 1 ]
        , urlFn = \x _ -> "#documents/" ++ document_id
        }


documentImage : Models.AppState -> Models.Document -> Html Models.Msg
documentImage state document =
    let
        { original_file_name, document_id, thumbnails } =
            document

        { countImages } =
            thumbnails

        currentImage =
            Helpers.safeValue thumbnails.currentImage 0

        content =
            case countImages of
                1 ->
                    Html.img
                        [ Html.Attributes.alt original_file_name
                        , Html.Attributes.src ("/documents/" ++ document_id ++ "/images/" ++ (toString currentImage))
                        , Html.Attributes.class "img-fluid"
                        ]
                        []

                _ ->
                    Html.div []
                        [ Bootstrap.Pagination.defaultConfig
                            |> Bootstrap.Pagination.ariaLabel "images-pagination"
                            |> Bootstrap.Pagination.align Bootstrap.General.HAlign.centerXs
                            |> Bootstrap.Pagination.itemsList (itemsList document)
                            |> Bootstrap.Pagination.view
                        , Html.img
                            [ Html.Attributes.alt original_file_name
                            , Html.Attributes.src ("/documents/" ++ document_id ++ "/images/" ++ (toString currentImage))
                            , Html.Attributes.class "img-fluid"
                            ]
                            []
                        ]
    in
        content


documentProperties : Models.AppState -> Models.Document -> Html Models.Msg
documentProperties state { original_file_name, document_id, document_type_id, comments, datetimes } =
    let
        { inserted_datetime, updated_datetime, original_file_datetime } =
            datetimes

        document_type =
            Helpers.getDocumentType state document_type_id
    in
        Html.div [ Html.Attributes.class "form-group" ]
            [ Html.dl []
                [ Html.dt [] [ Html.text "Document ID" ]
                , Html.dd [] [ Html.text document_id ]
                , Html.dt [] [ Html.text "Document type" ]
                , Html.dd [] [ Html.text document_type.name ]
                , Html.dt [] [ Html.text "Original file name" ]
                , Html.dd [] [ Html.text original_file_name ]
                , Html.dt [] [ Html.text "Uploaded date time" ]
                , Html.dd [] [ Html.text (Helpers.dateTimeToString inserted_datetime) ]
                , Html.dt [] [ Html.text "Updated date time" ]
                , Html.dd [] [ Html.text (Helpers.dateTimeToString (Helpers.safeValue updated_datetime Helpers.defaultDateTime)) ]
                , Html.dt [] [ Html.text "Original date time" ]
                , Html.dd [] [ Html.text (Helpers.dateTimeToString original_file_datetime) ]
                , Html.dt [] [ Html.text "Comments" ]
                , Html.dd []
                    [ Bootstrap.Form.Textarea.textarea
                        [ Bootstrap.Form.Textarea.id "comments"
                        , Bootstrap.Form.Textarea.defaultValue (Helpers.safeValue comments "")
                        , Bootstrap.Form.Textarea.rows 5
                        , Bootstrap.Form.Textarea.attrs
                            [ (Html.Attributes.map Helpers.debounce <|
                                Html.Events.onInput (Models.UpdateDocumentComments <| document_id)
                              )
                            ]
                        ]
                    ]
                ]
            ]


documentDetails : Models.AppState -> Models.Document -> Html Models.Msg
documentDetails state document =
    let
        { document_id } =
            document

        { route } =
            state

        leftView =
            case route of
                Routing.DocumentProperties _ ->
                    documentProperties state document

                Routing.Document _ ->
                    documentImage state document

                _ ->
                    Bootstrap.Alert.simpleWarning [] [ Html.text ("Panel not implement yet. ;)") ]
    in
        Html.div []
            [ confirmDelete state document
            , Bootstrap.ButtonGroup.linkButtonGroup
                [ Bootstrap.ButtonGroup.attrs
                    [ Html.Attributes.attribute "data-toggle" ""
                    , Html.Attributes.class "mr-2"
                    ]
                ]
                [ Bootstrap.ButtonGroup.linkButton
                    [ Bootstrap.Button.light
                    , Bootstrap.Button.attrs
                        [ Html.Attributes.href ("#documents/" ++ document_id)
                        , Html.Attributes.classList [ ( "active", (==) route (Routing.Document document_id) ) ]
                        ]
                    ]
                    [ Html.text "Preview" ]
                , Bootstrap.ButtonGroup.linkButton
                    [ Bootstrap.Button.light
                    , Bootstrap.Button.attrs
                        [ Html.Attributes.href ("#documents/" ++ document_id ++ "/properties")
                        , Html.Attributes.classList [ ( "active", (==) route (Routing.DocumentProperties document_id) ) ]
                        ]
                    ]
                    [ Html.text "Properties" ]
                ]
            , Bootstrap.ButtonGroup.linkButtonGroup
                [ Bootstrap.ButtonGroup.attrs
                    [ Html.Attributes.attribute "data-toggle" ""
                    , Html.Attributes.class "mr-2"
                    ]
                ]
                [ Bootstrap.ButtonGroup.linkButton
                    [ Bootstrap.Button.info
                    , Bootstrap.Button.attrs
                        [ Html.Attributes.href <| (++) "/documents/" document_id
                        , Html.Attributes.target "blank"
                        ]
                    ]
                    [ Html.text "Download" ]
                , Bootstrap.ButtonGroup.linkButton
                    [ Bootstrap.Button.danger
                    , Bootstrap.Button.onClick (Models.ShowModal)
                    , Bootstrap.Button.attrs
                        [ Html.Attributes.href "#"
                        ]
                    ]
                    [ Html.text "Delete" ]
                ]
            , Html.hr [] []
            , leftView
            ]


documentNotFound : Models.AppState -> String -> Html Models.Msg
documentNotFound state documentId =
    Bootstrap.Alert.simpleWarning [] [ Html.text ("Document " ++ documentId ++ " is not found!") ]
