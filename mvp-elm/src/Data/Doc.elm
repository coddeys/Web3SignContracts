module Data.Doc exposing (AssignedAttrs, Doc(..), LitAttrs, UploadedAttrs, addresses, cid, decoder, fileSize, name, step)

import Data.EncryptionKey as EncryptionKey exposing (EncryptionKey)
import Data.Lighthouse as Lighthouse exposing (Lighthouse)
import Data.Lighthouse.Upload as LighthouseUpload
import Data.Lit.Metadata as Lit
import Data.MetaMask.Address as MetaMask
import Data.Sign as Sign exposing (Sign)
import FileValue exposing (File)
import Json.Decode
import Json.Encode
import Maybe.Extra as Maybe


type Doc
    = Prepared File
    | Assigned AssignedAttrs
    | Uploaded UploadedAttrs
    | Lit LitAttrs
      --
    | Lighthouse Lighthouse


type alias AssignedAttrs =
    { addresses : MetaMask.Address
    , file : File
    }


type alias UploadedAttrs =
    { upload : LighthouseUpload.Upload
    , address : Maybe MetaMask.Address
    , file : Maybe File
    }


type alias LitAttrs =
    { metadata : Lit.Metadata
    , address : Maybe MetaMask.Address
    }


decoder : Json.Decode.Decoder Doc
decoder =
    Json.Decode.oneOf
        [ decoderLit
        , decoderLighthouseUpload
        , decoderAssigned
        , decoderPrepared
        ]


decoderLit : Json.Decode.Decoder Doc
decoderLit =
    Json.Decode.map2 LitAttrs
        (Json.Decode.field "metadata" Lit.decoder)
        (Json.Decode.maybe <| Json.Decode.field "address" MetaMask.decoder)
        |> Json.Decode.map Lit


decoderLighthouse : Json.Decode.Decoder Doc
decoderLighthouse =
    Json.Decode.map Lighthouse
        Lighthouse.decoder


decoderLighthouseUpload : Json.Decode.Decoder Doc
decoderLighthouseUpload =
    Json.Decode.map3 UploadedAttrs
        (Json.Decode.field "lighthouse" LighthouseUpload.decoder)
        (Json.Decode.maybe <| Json.Decode.field "address" MetaMask.decoder)
        (Json.Decode.maybe <| Json.Decode.field "file" FileValue.decoder)
        |> Json.Decode.map Uploaded


decoderAssigned : Json.Decode.Decoder Doc
decoderAssigned =
    Json.Decode.map2 AssignedAttrs
        (Json.Decode.field "address" MetaMask.decoder)
        (Json.Decode.field "file" FileValue.decoder)
        |> Json.Decode.map Assigned


decoderPrepared : Json.Decode.Decoder Doc
decoderPrepared =
    Json.Decode.field "file" FileValue.decoder
        |> Json.Decode.map Prepared


fileSize : Doc -> Int
fileSize doc =
    case doc of
        Prepared file ->
            file.size

        Assigned attrs ->
            attrs.file.size

        Uploaded attrs ->
            LighthouseUpload.size attrs.upload

        Lighthouse lighthouse ->
            Lighthouse.fileSize lighthouse

        Lit attrs ->
            attrs.metadata.size


name : Doc -> String
name doc =
    case doc of
        Prepared file ->
            file.name

        Assigned attrs ->
            attrs.file.name

        Uploaded attrs ->
            LighthouseUpload.name attrs.upload

        Lighthouse lighthouse ->
            Lighthouse.fileName lighthouse

        Lit attrs ->
            attrs.metadata.name


cid : Doc -> Maybe String
cid doc =
    case doc of
        Prepared _ ->
            Nothing

        Assigned attrs ->
            Nothing

        Uploaded attrs ->
            Just <| LighthouseUpload.cid attrs.upload

        Lighthouse lighthouse ->
            Just lighthouse.cid

        Lit attrs ->
            Just attrs.metadata.cid


addresses : Doc -> Maybe MetaMask.Address
addresses doc =
    case doc of
        Prepared _ ->
            Nothing

        Assigned attrs ->
            Just attrs.addresses

        Uploaded attrs ->
            attrs.address

        Lighthouse lighthouse ->
            Nothing

        Lit attrs ->
            -- TODO: get addresses from AccessControlCondition
            -- Lit.addresses attrs.metadata
            --     |> List.head
            attrs.address


step : Doc -> String
step doc =
    case doc of
        Prepared _ ->
            "draft"

        Assigned attrs ->
            "assigned"

        Uploaded attrs ->
            "uploaded"

        Lighthouse lighthouse ->
            "encrypted"

        Lit attrs ->
            "decrypted"
