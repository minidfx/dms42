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


pageItem : Models.Document -> Int -> String -> Html Models.Msg
pageItem { document_id, thumbnails } page label =
    let
        currentImage =
            Helpers.safeValue thumbnails.currentImage 0
    in
        Html.li
            [ Html.Attributes.class "page-item"
            , Html.Attributes.classList [ ( "active", currentImage == page ) ]
            ]
            [ Html.a
                [ Html.Attributes.class "page-link"
                , Html.Events.onClick (Models.ChangeDocumentPage document_id page)
                ]
                [ Html.text label ]
            ]


documentImage : Models.AppState -> Models.Document -> Html Models.Msg
documentImage state document =
    let
        { original_file_name, document_id, thumbnails } =
            document

        { countImages } =
            thumbnails

        currentImage =
            Helpers.safeValue thumbnails.currentImage 0

        pages =
            case countImages of
                0 ->
                    []

                1 ->
                    []

                x ->
                    List.concat
                        [ [ pageItem document 0 "First" ]
                        , List.map (\x -> pageItem document x (toString x)) (List.range 1 (x - 2))
                        , [ pageItem document (x - 1) "Last" ]
                        ]
    in
        Html.div []
            [ Html.nav []
                [ Html.ul [ Html.Attributes.class "pagination justify-content-center" ]
                    pages
                ]
            , Html.img
                [ Html.Attributes.alt original_file_name
                , Html.Attributes.src ("/documents/" ++ document_id ++ "/images/" ++ (toString currentImage))
                , Html.Attributes.class "img-fluid"
                ]
                []
            ]


documentProperties : Models.AppState -> Models.Document -> Html Models.Msg
documentProperties state { original_file_name, document_id, document_type_id, comments, datetimes } =
    let
        { inserted_datetime, updated_datetime, original_file_datetime } =
            datetimes
    in
        Html.div [ Html.Attributes.class "form-group" ]
            [ Html.dl []
                [ Html.dt [] [ Html.text "Document ID" ]
                , Html.dd [] [ Html.text document_id ]
                , Html.dt [] [ Html.text "Document type" ]
                , Html.dd [] [ Html.text document_type_id ]
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
        Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col-8" ]
                [ leftView
                ]
            , Html.div [ Html.Attributes.class "col-4" ]
                [ Bootstrap.ButtonGroup.linkButtonGroup
                    [ Bootstrap.ButtonGroup.vertical
                    , Bootstrap.ButtonGroup.attrs [ Html.Attributes.attribute "data-toggle" "" ]
                    ]
                    [ Bootstrap.ButtonGroup.linkButton
                        [ Bootstrap.Button.light
                        , Bootstrap.Button.attrs
                            [ Html.Attributes.href ("#documents/" ++ document_id)
                            , Html.Attributes.classList [ ( "active", route == Routing.Document document_id ) ]
                            ]
                        ]
                        [ Html.text "Preview" ]
                    , Bootstrap.ButtonGroup.linkButton
                        [ Bootstrap.Button.light
                        , Bootstrap.Button.attrs
                            [ Html.Attributes.href ("#documents/" ++ document_id ++ "/properties")
                            , Html.Attributes.classList [ ( "active", route == Routing.DocumentProperties document_id ) ]
                            ]
                        ]
                        [ Html.text "Properties" ]
                    ]
                ]
            ]


documentNotFound : Models.AppState -> String -> Html Models.Msg
documentNotFound state documentId =
    Bootstrap.Alert.simpleWarning [] [ Html.text ("Document " ++ documentId ++ " is not found!") ]
