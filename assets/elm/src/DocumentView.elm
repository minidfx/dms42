module DocumentView exposing (..)

import Html exposing (Html)
import Html.Attributes
import Models
import Routing
import Helpers
import Bootstrap.Alert
import Bootstrap.ButtonGroup
import Bootstrap.Button
import Bootstrap.Form.Textarea
import Debouncer.Basic


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


documentImage : Models.AppState -> Models.Document -> Html Models.Msg
documentImage state { original_file_name, document_id } =
    Html.img
        [ Html.Attributes.alt original_file_name
        , Html.Attributes.src ("/documents/" ++ document_id ++ "/images/0")
        , Html.Attributes.class "img-fluid"
        ]
        []


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
                        , Bootstrap.Form.Textarea.value (Helpers.safeValue comments "")
                        , Bootstrap.Form.Textarea.rows 5
                        , (Models.UpdateDocumentComments <| document_id |> Debouncer.Basic.provideInput |> Models.DebounceOneSecond) |> Bootstrap.Form.Textarea.onInput
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

        previewButtonState =
            case route of
                Routing.Document _ ->
                    True

                _ ->
                    False

        propertiesButtonState =
            case route of
                Routing.DocumentProperties _ ->
                    True

                _ ->
                    False

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
                            , Html.Attributes.classList [ ( "active", previewButtonState ) ]
                            ]
                        ]
                        [ Html.text "Preview" ]
                    , Bootstrap.ButtonGroup.linkButton
                        [ Bootstrap.Button.light
                        , Bootstrap.Button.attrs
                            [ Html.Attributes.href ("#documents/" ++ document_id ++ "/properties")
                            , Html.Attributes.classList [ ( "active", propertiesButtonState ) ]
                            ]
                        ]
                        [ Html.text "Properties" ]
                    ]
                ]
            ]


documentNotFound : Models.AppState -> String -> Html Models.Msg
documentNotFound state documentId =
    Bootstrap.Alert.simpleWarning [] [ Html.text ("Document " ++ documentId ++ " is not found!") ]
