module Pages.Docs exposing (Model, Msg, page)

import Auth
import Bytes exposing (Bytes)
import Data.Doc as Doc exposing (Doc(..), addresses)
import Data.EncryptionKey as EncryptionKey exposing (EncryptionKey)
import Data.Lighthouse as Lighthouse
import Data.Lighthouse.Upload as LighthouseUpload
import Data.MetaMask.Address as Address exposing (Address)
import Data.Sign as Sign exposing (Sign)
import Dict exposing (Dict)
import Effect exposing (Effect)
import File
import File.Download
import File.Select as Select
import FileValue exposing (File, hiddenInputSingle)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode
import Json.Encode
import Layouts
import List.Extra as List
import Maybe.Extra as Maybe
import Page exposing (Page)
import Route exposing (Route)
import Set exposing (Set)
import Shared
import Shared.Model exposing (Docs, docsKey)
import Task
import Time
import View exposing (View)
import Views.Action.Button as ActionButton exposing (ActionButton)


page : Auth.User -> Shared.Model -> Route () -> Page Model Msg
page user shared route =
    Page.new
        { init = init
        , update = update shared.docs
        , subscriptions = subscriptions
        , view = view shared.docs
        }
        |> Page.withLayout (layout user)


layout : Auth.User -> Model -> Layouts.Layout
layout user model =
    Layouts.Sidebar
        { sidebar =
            { title = ""
            , user = user
            }
        }



-- INIT


type alias Model =
    { step : Maybe SigningStep
    , sorted : Maybe ( Column, Bool )
    , selected : Set String
    , uploadedToIPFS : Set String
    }


type SigningStep
    = AddRecipient RecipientAttrs


type alias RecipientAttrs =
    { address : Address
    , name : String
    , key : String
    , data : String
    }


updatePreviewAddress : String -> SigningStep -> SigningStep
updatePreviewAddress str pr =
    case pr of
        AddRecipient step ->
            AddRecipient { step | address = Address.fromString str }


type Column
    = SelectedCol
    | Step
    | Name
    | Addresses
    | UploadedToIPFS
    | Size


allColumns : List Column
allColumns =
    [ SelectedCol
    , Name
    , Addresses
    , UploadedToIPFS
    , Size
    , Step
    ]


isSorted : Column -> Bool
isSorted col =
    case col of
        SelectedCol ->
            False

        Step ->
            True

        Addresses ->
            True

        Name ->
            True

        UploadedToIPFS ->
            True

        Size ->
            True


colToString : Column -> String
colToString col =
    case col of
        SelectedCol ->
            ""

        Step ->
            "Status"

        Addresses ->
            "Assigned"

        Name ->
            "Name"

        UploadedToIPFS ->
            "IPFS"

        Size ->
            "Size"


init : () -> ( Model, Effect Msg )
init () =
    ( { step = Nothing
      , sorted = Just ( Name, False )
      , selected = Set.empty
      , uploadedToIPFS = Set.empty
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = SyncClicked
    | PdfLoaded File
    | AddRecipientTriggered RecipientAttrs
    | PreparedViewClicked String File
    | PreviewAddressesChanged String
    | SaveAsDraftClicked String Address
    | SignAndUploadClicked String Address
    | AddressesActionClicked String File Address
    | DecryptAndViewClicked String String
    | PreviewClosed
    | DeleteClicked (Set String)
    | SetSorted ( Column, Bool )
    | SetSelected String
    | UploadedToIPFSClicked (Set String)


update : Docs -> Msg -> Model -> ( Model, Effect Msg )
update docs msg model =
    case msg of
        SyncClicked ->
            ( model
            , Effect.syncOut
            )

        PdfLoaded pdf ->
            let
                key =
                    docsKey docs
            in
            ( { model | selected = Set.singleton key }
            , [ Effect.upload key pdf
              , movedToAddRecipientEff key pdf Nothing
              ]
                |> Effect.batch
            )

        AddRecipientTriggered step ->
            ( { model | step = Just (AddRecipient step) }
            , Effect.none
            )

        PreparedViewClicked key file ->
            ( { model | selected = Set.singleton key }
            , movedToAddRecipientEff key file Nothing
            )

        PreviewAddressesChanged str ->
            ( { model
                | step =
                    model.step
                        |> Maybe.map (updatePreviewAddress str)
              }
            , Effect.none
            )

        SaveAsDraftClicked key address ->
            ( { model
                | step = Nothing
                , selected = Set.empty
              }
            , storeAddressEff key address
            )

        SignAndUploadClicked key address ->
            ( { model
                | step = Nothing
                , selected = Set.empty
              }
            , Effect.signAndUpload key address
            )

        AddressesActionClicked key file address ->
            ( { model | selected = Set.singleton key }
            , movedToAddRecipientEff key file (Just address)
            )

        DecryptAndViewClicked key lighthouse ->
            ( model
            , decryptEff key lighthouse
            )

        PreviewClosed ->
            ( { model
                | step = Nothing
                , selected = Set.empty
              }
            , Effect.none
            )

        DeleteClicked set ->
            ( { model | selected = Set.empty }
            , set
                |> Set.toList
                |> List.map Effect.del
                |> Effect.batch
            )

        UploadedToIPFSClicked set ->
            ( { model
                | selected = Set.empty
                , uploadedToIPFS = Set.union set model.uploadedToIPFS
              }
            , set
                |> Set.toList
                |> List.map Effect.uploadToIPFS
                |> Effect.batch
            )

        SetSorted ( col, bool ) ->
            ( { model | sorted = Just ( col, bool ) }
            , Effect.none
            )

        SetSelected int ->
            ( { model
                | selected =
                    if Set.member int model.selected then
                        Set.remove int model.selected

                    else
                        Set.insert int model.selected
              }
            , Effect.none
            )


storeAddressEff : String -> Address -> Effect Msg
storeAddressEff key address =
    [ ( "key", Json.Encode.string key )
    , ( "address", Address.encode address )
    ]
        |> Json.Encode.object
        |> Effect.set


movedToAddRecipientEff : String -> File -> Maybe Address -> Effect Msg
movedToAddRecipientEff key file address =
    let
        addr =
            address
                |> Maybe.withDefault (Address.fromString "")

        toRecipientAttrs =
            RecipientAttrs addr file.name key
    in
    file.value
        |> Json.Decode.decodeValue File.decoder
        |> Result.map
            (File.toUrl
                >> Task.perform (AddRecipientTriggered << toRecipientAttrs)
                >> Effect.sendCmd
            )
        |> Result.withDefault Effect.none


decryptEff : String -> String -> Effect msg
decryptEff key cid =
    cid
        |> Effect.downloadAndDecryptIPFS key



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Docs -> Model -> View Msg
view docs model =
    { title = "Docs"
    , body =
        [ viewHeader model docs
        , docs
            |> Dict.toList
            |> sortBy model.sorted
            |> viewDocs model
        ]
    }


sortBy : Maybe ( Column, Bool ) -> List ( String, Doc ) -> List ( String, Doc )
sortBy sorted xs =
    case sorted of
        Just ( col, bool ) ->
            if bool then
                xs
                    |> List.sortBy (Doc.name << Tuple.second)
                    |> List.reverse

            else
                List.sortBy (Doc.name << Tuple.second) xs

        Nothing ->
            xs


viewHeader : Model -> Docs -> Html Msg
viewHeader model docs =
    div
        [ style "display" "flex"
        , style "justify-content" "space-between"
        ]
        [ div [] [ h1 [] [ Html.text <| "All Docs(" ++ String.fromInt (Dict.size docs) ++ ")" ] ]
        , div
            [ style "display" "flex"
            , style "height" "100%"
            , style "gap" "1em"
            ]
            (docs
                |> Dict.filter (\k _ -> Set.member k model.selected)
                |> Dict.toList
                |> actionButtons
            )
        ]


actionButtons : List ( String, Doc ) -> List (Html Msg)
actionButtons docs =
    case docs of
        [] ->
            actionButtonsInactive
                ++ viewAdd

        [ ( key, Doc.Prepared file ) ] ->
            actionPreparedButtonsDoc key file

        [ ( key, Doc.Assigned attrs ) ] ->
            actionAssignedButtonsDoc key attrs

        [ ( key, Uploaded attrs ) ] ->
            actionUploadedButtonsDoc key attrs

        [ ( key, Lit attrs ) ] ->
            actionLitButtonsDoc key attrs

        [ ( key, Lighthouse lighthouse ) ] ->
            actionLighthouseButtonsDoc key lighthouse

        _ ->
            actionButtonsInactive
                ++ viewAdd


viewAdd : List (Html Msg)
viewAdd =
    [ div []
        [ hiddenInputSingle "add" [ "application/pdf" ] PdfLoaded
        , label [ title "Prepare for signing", for "add", attribute "role" "button" ] [ text "Prepare" ]
        ]
    ]


actionButtonsInactive : List (Html msg)
actionButtonsInactive =
    [ "Upload", "Cancel", "View" ]
        |> List.map outlineButtonDisabled


viewActionButton : { label : String, msg : msg } -> Html msg
viewActionButton { label, msg } =
    button
        [ onClick msg ]
        [ text label ]


outlineButtonDisabled : String -> Html msg
outlineButtonDisabled t =
    button [ class "outline", disabled True ] [ text t ]


outlineButtonDoc : { label : String, msg : msg } -> Html msg
outlineButtonDoc { label, msg } =
    button
        [ class "outline", onClick msg ]
        [ text label ]


actionPreparedButtonsDoc : String -> File -> List (Html Msg)
actionPreparedButtonsDoc key file =
    [ outlineButtonDoc
        { label = "Cancel"
        , msg = DeleteClicked (Set.singleton key)
        }
    , viewActionButton
        { label = "Addresses"
        , msg = PreparedViewClicked key file
        }
    ]


actionAssignedButtonsDoc : String -> Doc.AssignedAttrs -> List (Html Msg)
actionAssignedButtonsDoc key attrs =
    [ outlineButtonDoc
        { label = "Cancel"
        , msg = DeleteClicked (Set.singleton key)
        }
    , outlineButtonDoc
        { label = "View"
        , msg = AddressesActionClicked key attrs.file attrs.addresses
        }
    , viewActionButton
        { label = "Sign&Upload"
        , msg = AddressesActionClicked key attrs.file attrs.addresses
        }
    ]


actionUploadedButtonsDoc : String -> Doc.UploadedAttrs -> List (Html Msg)
actionUploadedButtonsDoc key attrs =
    [ viewActionButton
        { label = "Decrypt&View"
        , msg = DecryptAndViewClicked key attrs.upload.cid
        }
    ]


actionLitButtonsDoc : String -> Doc.LitAttrs -> List (Html Msg)
actionLitButtonsDoc key attrs =
    [ viewActionButton
        { label = "View"
        , msg = DecryptAndViewClicked key attrs.metadata.cid
        }
    ]


actionLighthouseButtonsDoc : String -> Lighthouse.Lighthouse -> List (Html Msg)
actionLighthouseButtonsDoc key lighthouse =
    [ viewActionButton
        { label = "Decrypt&View"
        , msg = DecryptAndViewClicked key (Lighthouse.cid lighthouse)
        }
    ]


viewDocs : Model -> List ( String, Doc ) -> Html Msg
viewDocs model docs =
    case model.step of
        Just step ->
            viewStep step

        Nothing ->
            div []
                [ table [ attribute "role" "grid" ]
                    [ viewThead model
                    , tbody [] (List.map (viewRow model.selected) docs)
                    ]
                ]


viewThead : Model -> Html Msg
viewThead model =
    let
        sorted =
            True
    in
    thead []
        [ tr []
            (allColumns
                |> List.map
                    (\x ->
                        if isSorted x then
                            viewThSorted model.sorted x

                        else
                            viewTh x
                    )
            )
        ]


viewTh : Column -> Html Msg
viewTh col =
    th
        [ attribute "scope" "col"
        ]
        [ small [] [ text <| colToString col ] ]


viewThSorted : Maybe ( Column, Bool ) -> Column -> Html Msg
viewThSorted sel col =
    let
        msg =
            case sel of
                Just ( col_, bool ) ->
                    if col_ == col then
                        SetSorted ( col, not bool )

                    else
                        SetSorted ( col, False )

                Nothing ->
                    SetSorted ( col, False )

        icon =
            case sel of
                Just ( col_, bool ) ->
                    if col_ == col then
                        if bool then
                            "↑"

                        else
                            "↓"

                    else
                        "↕"

                Nothing ->
                    "↕"
    in
    th
        [ attribute "scope" "col"
        , onClick msg
        ]
        [ small [] [ text <| colToString col ++ icon ] ]


type alias DialogConfig =
    { name : String
    , address : Address
    , key : String
    , data : String
    }


viewStep : SigningStep -> Html Msg
viewStep step =
    case step of
        AddRecipient attrs ->
            viewStepAddRecipient attrs


viewStepAddRecipient : RecipientAttrs -> Html Msg
viewStepAddRecipient attrs =
    viewDialog
        { name = attrs.name
        , data = attrs.data
        , key = attrs.key
        , address = attrs.address
        }


viewDialog : DialogConfig -> Html Msg
viewDialog { name, data, address, key } =
    let
        isEmpty =
            String.isEmpty <| Address.string address
    in
    div [ style "width" "100vw" ]
        [ node "dialog"
            [ attribute "open" "" ]
            [ article
                [ style "max-width" "90%"
                , style "width" "90%"
                , style "max-height" "90%"
                , style "height" "100%"
                , style "overflow" "hidden"
                ]
                [ header []
                    [ div []
                        [ span
                            [ class "close"
                            , attribute "arith-label" "Close"
                            , onClick <| PreviewClosed
                            ]
                            []
                        , h3 [] [ text name ]
                        ]
                    , viewPreviewAddresses address
                    , div
                        [ class "grid"
                        , style "grid-template-columns" "25% 25%"
                        , style "justify-content" "end"
                        , title <|
                            case isEmpty of
                                False ->
                                    ""

                                True ->
                                    "The Address field is required"
                        ]
                        [ button
                            [ class "outline"
                            , case isEmpty of
                                False ->
                                    onClick <| SaveAsDraftClicked key address

                                True ->
                                    disabled True
                            ]
                            [ text "Save as Draft" ]
                        , span
                            []
                            [ button
                                [ case isEmpty of
                                    False ->
                                        onClick <| SignAndUploadClicked key address

                                    True ->
                                        disabled True
                                ]
                                [ text "Sign and Upload" ]
                            ]
                        ]
                    ]
                , div
                    [ style "width" "100%"
                    , style "height" "100%"
                    ]
                    [ object
                        [ style "width" "100%"
                        , style "height" "100%"
                        , style "padding-bottom" "2rem"
                        , attribute "data" data
                        ]
                        []
                    ]
                ]
            ]
        ]


viewPreviewAddresses : Address -> Html Msg
viewPreviewAddresses address =
    details [ attribute "open" "" ]
        [ summary [] [ text "Addresses *" ]
        , input
            [ type_ "input"
            , onInput PreviewAddressesChanged
            , address
                |> Address.string
                |> value
            , placeholder "MetaMask wallet Address"
            ]
            []
        , small [] [ text "Enter the public address of the MetaMask wallet." ]
        ]


viewRow : Set String -> ( String, Doc ) -> Html Msg
viewRow selected ( key, doc ) =
    let
        isSelected =
            Set.member key selected
    in
    tr
        [ attribute "scope" "col"
        , if isSelected then
            style "background-color" "var(--dropdown-hover-background-color)"

          else
            style "" ""
        , class "warning"
        ]
        [ td [ onClick (SetSelected key) ] [ input [ type_ "checkbox", checked isSelected ] [] ]
        , td []
            [ case doc of
                Prepared file ->
                    strong
                        [ onClick (PreparedViewClicked key file) ]
                        [ span [ class "link", href "" ] [ text <| Doc.name doc ] ]

                Assigned attrs ->
                    strong
                        [ onClick (AddressesActionClicked key attrs.file attrs.addresses) ]
                        [ span [ class "link" ] [ text <| Doc.name doc ] ]

                Uploaded attrs ->
                    strong
                        []
                        [ span
                            [ class "link"
                            , onClick <| DecryptAndViewClicked key (LighthouseUpload.cid attrs.upload)
                            ]
                            [ attrs.file
                                |> Maybe.map .name
                                |> Maybe.withDefault (LighthouseUpload.name attrs.upload)
                                |> text
                            ]
                        ]

                Lighthouse lighthouse ->
                    strong
                        []
                        [ span
                            [ class "link"
                            , onClick <| DecryptAndViewClicked key (Lighthouse.cid lighthouse)
                            ]
                            [ text <| Lighthouse.fileName lighthouse ]
                        ]

                Lit attrs ->
                    strong
                        []
                        [ span
                            [ class "link"
                            , onClick <| DecryptAndViewClicked key attrs.metadata.cid
                            ]
                            [ text <| attrs.metadata.name ]
                        ]
            ]
        , td [] [ viewAddresses doc ]
        , td [] [ viewUploadToIPFS doc ]
        , td []
            [ small []
                [ doc
                    |> Doc.fileSize
                    |> String.fromInt
                    |> (\x -> x ++ "B")
                    |> text
                ]
            ]
        , td [] [ text (Doc.step doc) ]
        ]


viewAddresses : Doc -> Html Msg
viewAddresses doc =
    case Doc.addresses doc of
        Nothing ->
            text ""

        Just address ->
            div
                [ style "max-width" "100px"
                , style "height" "1.4em"
                , style "overflow" "hidden"
                , style "text-overflow" "ellipsis"
                , address
                    |> Address.string
                    |> title
                ]
                [ small []
                    [ text <| Address.string address ]
                ]


viewUploadToIPFS : Doc -> Html Msg
viewUploadToIPFS doc =
    case Doc.cid doc of
        Just cid ->
            div
                [ style "max-width" "100px"
                , style "height" "1.4em"
                , style "overflow" "hidden"
                , style "text-overflow" "ellipsis"
                , title cid
                ]
                [ small []
                    [ text cid ]
                ]

        Nothing ->
            text ""


toUtcString : Time.Posix -> String
toUtcString time =
    String.fromInt (Time.toHour Time.utc time)
        ++ ":"
        ++ String.fromInt (Time.toMinute Time.utc time)
        ++ ":"
        ++ String.fromInt (Time.toSecond Time.utc time)
        ++ " (UTC)"
