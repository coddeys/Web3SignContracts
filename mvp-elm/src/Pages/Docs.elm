module Pages.Docs exposing (Model, Msg, page)

import Auth
import Bytes exposing (Bytes)
import Data.Doc as Doc exposing (Doc)
import Data.EncryptionKey as EncryptionKey exposing (EncryptionKey)
import Data.Sign as Sign exposing (Sign)
import Dict exposing (Dict)
import Effect exposing (Effect)
import File
import File.Download
import File.Select as Select
import FileValue exposing (File, hiddenInputSingle)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode
import Json.Encode
import Layouts
import List.Extra as List
import Maybe.Extra as Maybe
import Page exposing (Page)
import Route exposing (Route)
import Set exposing (Set)
import Shared
import Shared.Model exposing (Docs)
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
    { preview : Maybe String
    , sorted : Maybe ( Column, Bool )
    , selected : Set Int
    , signed : Set Int
    , encrypted : Set Int
    , uplodedToIPFS : Set Int
    }


type Column
    = SelectedCol
    | Name
    | Signed
    | Encrypted
    | UploadedToIPFS
    | Size
    | Modified


allColumns : List Column
allColumns =
    [ SelectedCol
    , Name
    , Signed
    , Encrypted
    , UploadedToIPFS
    , Size
    , Modified
    ]


isSorted : Column -> Bool
isSorted col =
    case col of
        SelectedCol ->
            False

        Name ->
            True

        Signed ->
            False

        Encrypted ->
            True

        UploadedToIPFS ->
            True

        Size ->
            True

        Modified ->
            True


colToString : Column -> String
colToString col =
    case col of
        SelectedCol ->
            ""

        Name ->
            "Name"

        Signed ->
            "Signed"

        Encrypted ->
            "Encrypted"

        UploadedToIPFS ->
            "IPFS"

        Size ->
            "Size"

        Modified ->
            "Modified"


init : () -> ( Model, Effect Msg )
init () =
    ( { preview = Nothing
      , sorted = Nothing
      , selected = Set.empty
      , signed = Set.empty
      , encrypted = Set.empty
      , uplodedToIPFS = Set.empty
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = SyncClicked
    | PdfLoaded File
    | UrlGen String
    | PreviewClicked Doc
    | PreviewClosed
    | DeleteClicked (Set Int)
    | SignClicked (Set Int)
    | SetSorted ( Column, Bool )
    | SetSelected Int
    | EncryptClicked (Set Int)
    | UploadedToIPFSClicked (Set Int)


update : Docs -> Msg -> Model -> ( Model, Effect Msg )
update docs msg model =
    case msg of
        SyncClicked ->
            ( model
            , Effect.syncOut
            )

        PdfLoaded pdf ->
            ( model
            , Effect.upload pdf
            )

        UrlGen str ->
            ( { model | preview = Just str }
            , Effect.none
            )

        PreviewClicked doc ->
            ( model
              -- TODO: Preview IPFS file
            , Doc.file doc
                |> Maybe.map .value
                |> Maybe.andThen (Result.toMaybe << Json.Decode.decodeValue File.decoder)
                |> Maybe.map
                    (\x ->
                        x
                            |> File.toUrl
                            |> Task.perform UrlGen
                            |> Effect.sendCmd
                    )
                |> Maybe.withDefault Effect.none
            )

        PreviewClosed ->
            ( { model | preview = Nothing }
            , Effect.none
            )

        DeleteClicked set ->
            ( { model | selected = Set.empty }
            , set
                |> Set.toList
                |> List.map Effect.del
                |> Effect.batch
            )

        SignClicked set ->
            ( { model
                | selected = Set.empty
                , signed = Set.union set model.signed
              }
            , set
                |> Set.toList
                |> List.map Effect.sign
                |> Effect.batch
            )

        EncryptClicked set ->
            ( { model
                | selected = Set.empty
                , encrypted = Set.union set model.encrypted
              }
            , set
                |> Set.toList
                |> List.map Effect.encrypt
                |> Effect.batch
            )

        UploadedToIPFSClicked set ->
            ( { model
                | selected = Set.empty
                , uplodedToIPFS = Set.union set model.uplodedToIPFS
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


sortBy : Maybe ( Column, Bool ) -> List ( Int, Doc ) -> List ( Int, Doc )
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
            ((Dict.filter (\k _ -> Set.member k model.selected) docs
                |> Dict.values
                |> actionButtons
                |> List.map (\b -> ActionButton.toHtml b model.selected docs)
             )
                ++ viewAdd
            )
        ]


actionButtons : List Doc -> List (ActionButton Msg)
actionButtons docs =
    case List.unique <| List.map Doc.isUploadedToIPFS docs of
        [] ->
            actionButtonsInactive

        [ False ] ->
            actionButtonsDocs

        [ True ] ->
            actionButtonsIPFS

        _ ->
            actionButtonsMixed


viewAdd : List (Html Msg)
viewAdd =
    [ div []
        [ hiddenInputSingle "add" [ "application/pdf" ] PdfLoaded
        , label [ for "add", attribute "role" "button" ] [ text "Prepare" ]
        ]
    ]


actionButtonsInactive : List (ActionButton msg)
actionButtonsInactive =
    [ "Upload", "Cancel", "View" ]
        |> List.map ActionButton.inactive


actionButtonsDocs : List (ActionButton Msg)
actionButtonsDocs =
    ([ { label = "Upload", toMsg = UploadedToIPFSClicked, isDisabled = isAlreadyUploadedToIPFS }
     , { label = "Cancel", toMsg = DeleteClicked, isDisabled = \_ _ -> False }
     ]
        |> List.map ActionButton.init
    )
        ++ [ ActionButton.initCustom
                { label = "View"
                , toMsg =
                    \keys docs ->
                        if Set.size keys == 1 then
                            Dict.values docs
                                |> List.head
                                |> Maybe.map PreviewClicked

                        else
                            Nothing
                , isDisabled = \keys _ -> Set.size keys /= 1
                }
           ]


actionButtonsIPFS : List (ActionButton Msg)
actionButtonsIPFS =
    ([]
        |> List.map ActionButton.init
    )
        ++ [ ActionButton.initCustom
                { label = "View"
                , toMsg =
                    \keys docs ->
                        if Set.size keys == 1 then
                            Dict.values docs
                                |> List.head
                                |> Maybe.map PreviewClicked

                        else
                            Nothing
                , isDisabled = \keys _ -> Set.size keys /= 1
                }
           ]


actionButtonsMixed : List (ActionButton Msg)
actionButtonsMixed =
    [ "Upload", "Cancel", "View" ]
        |> List.map ActionButton.inactive


isAlreadyUploadedToIPFS : Set Int -> Dict Int Doc -> Bool
isAlreadyUploadedToIPFS selected docs =
    selected
        |> Set.toList
        |> List.filterMap (\k -> Dict.get k docs)
        |> List.any (\d -> Doc.isUploadedToIPFS d)


isAlreadySigned : Set Int -> Dict Int Doc -> Bool
isAlreadySigned selected docs =
    selected
        |> Set.toList
        |> List.filterMap (\k -> Dict.get k docs)
        |> List.any (\d -> not (Maybe.isNothing (Doc.signed d)))


isAlreadyEncrypted : Set Int -> Dict Int Doc -> Bool
isAlreadyEncrypted selected docs =
    selected
        |> Set.toList
        |> List.filterMap (\k -> Dict.get k docs)
        |> List.any (\d -> not (Maybe.isNothing (Doc.encryptionKey d)))


viewDocs : Model -> List ( Int, Doc ) -> Html Msg
viewDocs model docs =
    div []
        [ table [ attribute "role" "grid" ]
            [ viewThead model
            , tbody [] (List.map (viewRow model) docs)
            ]
        , viewPreview model
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


viewPreview : Model -> Html Msg
viewPreview model =
    case model.preview of
        Just preview ->
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
                            [ a [ class "close", attribute "arith-label" "Close", onClick PreviewClosed ] []
                            , text "Preview"
                            ]
                        , div
                            [ style "width" "100%"
                            , style "height" "100%"
                            ]
                            [ object
                                [ style "width" "100%"
                                , style "height" "100%"
                                , style "padding-bottom" "2rem"
                                , attribute "data" preview
                                ]
                                []
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""


viewRow : Model -> ( Int, Doc ) -> Html Msg
viewRow { signed, selected, encrypted, uplodedToIPFS } ( key, doc ) =
    let
        isSelected =
            Set.member key selected
    in
    tr
        [ attribute "scope" "col"
        , onClick (SetSelected key)
        , if isSelected then
            style "background-color" "var(--dropdown-hover-background-color)"

          else
            style "" ""
        , class "warning"
        ]
        [ td [] [ input [ type_ "checkbox", checked isSelected ] [] ]
        , td [] [ strong [ onClick (PreviewClicked doc) ] [ a [ href "" ] [ text <| Doc.name doc ] ] ]
        , td [] [ viewSigned (Set.member key signed) doc ]
        , td [] [ viewEncrypted (Set.member key encrypted) doc ]
        , td [] [ viewUploadToIPFS (Set.member key uplodedToIPFS) doc ]
        , td []
            [ small []
                [ doc
                    |> Doc.fileSize
                    |> Maybe.map String.fromInt
                    |> Maybe.map (\x -> x ++ "B")
                    |> Maybe.withDefault ""
                    |> text
                ]
            ]
        , td []
            [ small []
                [ Doc.file doc
                    |> Maybe.map (toUtcString << .lastModified)
                    |> Maybe.withDefault ""
                    |> text
                ]
            ]
        ]


viewUploadToIPFS : Bool -> Doc -> Html Msg
viewUploadToIPFS isLoading doc =
    case Doc.lighthouse doc of
        Just lighthouse ->
            div
                [ style "max-width" "100px"
                , style "height" "1.4em"
                , style "overflow" "hidden"
                , style "text-overflow" "ellipsis"
                , title lighthouse.hash
                ]
                [ small
                    [ if isLoading && (not <| Doc.isUploadedToIPFS doc) then
                        attribute "aria-busy" "true"

                      else
                        style "" ""
                    ]
                    [ text lighthouse.hash ]
                ]

        Nothing ->
            text ""


viewEncrypted : Bool -> Doc -> Html Msg
viewEncrypted isLoading doc =
    div
        [ style "max-width" "100px"
        , style "height" "1.4em"
        , style "overflow" "hidden"
        , style "text-overflow" "ellipsis"
        , title <|
            case Doc.encryptionKey doc of
                Just encryptionKey ->
                    EncryptionKey.toString encryptionKey

                Nothing ->
                    "The document is not yet encryptionKey"
        ]
        [ small
            [ if isLoading && (Maybe.isNothing <| Doc.encryptionKey doc) then
                attribute "aria-busy" "true"

              else
                style "" ""
            ]
            [ text <|
                case Doc.encryptionKey doc of
                    Just encryptionKey ->
                        "yes"

                    Nothing ->
                        "no"
            ]
        ]


viewSigned : Bool -> Doc -> Html Msg
viewSigned isLoading doc =
    div
        [ style "max-width" "100px"
        , style "height" "1.4em"
        , style "overflow" "hidden"
        , style "text-overflow" "ellipsis"
        , title <|
            case Doc.signed doc of
                Just sign ->
                    Sign.toString sign

                Nothing ->
                    "The document is not yet signed"
        ]
        [ small
            [ if isLoading && (Maybe.isNothing <| Doc.signed doc) then
                attribute "aria-busy" "true"

              else
                style "" ""
            ]
            [ text <|
                case Doc.signed doc of
                    Just sign ->
                        Sign.toString sign

                    Nothing ->
                        "not signed"
            ]
        ]


toUtcString : Time.Posix -> String
toUtcString time =
    String.fromInt (Time.toHour Time.utc time)
        ++ ":"
        ++ String.fromInt (Time.toMinute Time.utc time)
        ++ ":"
        ++ String.fromInt (Time.toSecond Time.utc time)
        ++ " (UTC)"
