module Pages.Docs exposing (Model, Msg, page)

import Auth
import Bytes exposing (Bytes)
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
import Page exposing (Page)
import Route exposing (Route)
import Set exposing (Set)
import Shared
import Shared.Model exposing (Doc, Docs)
import Task
import Time
import View exposing (View)


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
    }


type Column
    = SelectedCol
    | Name
    | Signed
    | Size
    | Modified


allColumns : List Column
allColumns =
    [ SelectedCol
    , Name
    , Signed
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
    | DownloadClicked (Set Int)
    | DownloadLoaded String Bytes
    | SignClicked (Set Int)
    | SetSorted ( Column, Bool )
    | SetSelected Int


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
            , doc.file.value
                |> Json.Decode.decodeValue File.decoder
                |> Result.map
                    (\x ->
                        x
                            |> File.toUrl
                            |> Task.perform UrlGen
                            |> Effect.sendCmd
                    )
                |> Result.withDefault Effect.none
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

        DownloadClicked set ->
            ( model
            , set
                |> Set.toList
                |> List.filterMap (\k -> Dict.get k docs)
                |> List.filterMap downloadTask
                |> List.map Effect.sendCmd
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

        DownloadLoaded name bytes ->
            ( model
            , bytes
                |> File.Download.bytes name "application/pdf"
                |> Effect.sendCmd
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


downloadTask : Doc -> Maybe (Cmd Msg)
downloadTask doc =
    let
        toBytes =
            Maybe.map File.toBytes << Result.toMaybe << Json.Decode.decodeValue File.decoder
    in
    toBytes doc.file.value
        |> Maybe.map (Task.perform <| DownloadLoaded doc.file.name)



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
                    |> List.sortBy (.name << .file << Tuple.second)
                    |> List.reverse

            else
                List.sortBy (.name << .file << Tuple.second) xs

        Nothing ->
            xs


viewHeader : Model -> Docs -> Html Msg
viewHeader model docs =
    div
        [ style "display" "flex"
        , style "justify-content" "space-between"
        ]
        [ div [] [ h1 [] [ Html.text <| "All Docs(" ++ String.fromInt (Dict.size docs) ++ ")" ] ]
        , div [ style "display" "flex", style "height" "100%" ] (viewActions model docs)
        ]


viewActions : Model -> Docs -> List (Html Msg)
viewActions model docs =
    let
        alreadySigned =
            model.selected
                |> Set.toList
                |> List.filterMap (\k -> Dict.get k docs)
                |> List.any (\d -> d.signed)
    in
    if Set.isEmpty model.selected then
        [ div []
            [ hiddenInputSingle "upload" [ "application/pdf" ] PdfLoaded
            , label [ for "upload", attribute "role" "button" ] [ text "+ Upload" ]
            ]
        ]

    else
        [ button [ class "outline", disabled alreadySigned, onClick (SignClicked model.selected) ] [ text "Sign" ]
        , button [ class "outline", onClick (DeleteClicked model.selected) ] [ text "Delete" ]
        , button [ class "outline", onClick (DownloadClicked model.selected) ] [ text "Download" ]
        ]


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
        [ text <| colToString col ]


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
        [ text <| colToString col ++ " " ++ icon ]


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
viewRow { signed, selected } ( key, doc ) =
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
        , td [] [ strong [ onClick (PreviewClicked doc) ] [ a [ href "" ] [ text doc.file.name ] ] ]
        , td [] [ viewSigned (Set.member key signed) doc ]
        , td [] [ span [] [ text <| String.fromInt doc.file.size ++ "B" ] ]
        , td [] [ span [] [ text <| toUtcString doc.file.lastModified ] ]
        ]


viewSigned : Bool -> Doc -> Html Msg
viewSigned isLoading doc =
    span
        [ if isLoading && not doc.signed then
            attribute "aria-busy" "true"

          else
            style "" ""
        ]
        [ text <|
            if doc.signed then
                "yes"

            else
                "no"
        ]


toUtcString : Time.Posix -> String
toUtcString time =
    String.fromInt (Time.toHour Time.utc time)
        ++ ":"
        ++ String.fromInt (Time.toMinute Time.utc time)
        ++ ":"
        ++ String.fromInt (Time.toSecond Time.utc time)
        ++ " (UTC)"
