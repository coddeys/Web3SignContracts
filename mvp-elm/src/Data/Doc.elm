module Data.Doc exposing (Doc, decoder, encryptionKey, file, fileSize, isUploadedToIPFS, lighthouse, name, signed)

import Data.EncryptionKey as EncryptionKey exposing (EncryptionKey)
import Data.Lighthouse as Lighthouse exposing (Lighthouse)
import Data.Sign as Sign exposing (Sign)
import FileValue exposing (File)
import Json.Decode
import Json.Encode
import Maybe.Extra as Maybe


type Doc
    = Doc DocAttrs
    | IPFS IPFSAttrs


type alias DocAttrs =
    { name : String
    , file : File
    , signed : Maybe Sign
    , encryptionKey : Maybe EncryptionKey
    }


type alias IPFSAttrs =
    { name : String
    , file : Maybe File
    , signed : Maybe Sign
    , encryptionKey : Maybe EncryptionKey
    , lighthouse : Lighthouse
    }


decoder : Json.Decode.Decoder Doc
decoder =
    Json.Decode.oneOf
        [ decoderIPFS
        , decoderDoc
        ]


decoderIPFS : Json.Decode.Decoder Doc
decoderIPFS =
    Json.Decode.map5 IPFSAttrs
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.maybe <| Json.Decode.field "file" FileValue.decoder)
        (Json.Decode.maybe <| Json.Decode.field "signed" Sign.decoder)
        (Json.Decode.maybe <| Json.Decode.field "encryptionKey" EncryptionKey.decoder)
        (Json.Decode.field "lighthouse" Lighthouse.decoder)
        |> Json.Decode.map IPFS


decoderDoc : Json.Decode.Decoder Doc
decoderDoc =
    Json.Decode.map4 DocAttrs
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "file" FileValue.decoder)
        (Json.Decode.maybe <| Json.Decode.field "signed" Sign.decoder)
        (Json.Decode.maybe <| Json.Decode.field "encryptionKey" EncryptionKey.decoder)
        |> Json.Decode.map Doc


isUploadedToIPFS : Doc -> Bool
isUploadedToIPFS doc =
    case doc of
        Doc attrs ->
            False

        IPFS attrs ->
            True


file : Doc -> Maybe File
file doc =
    case doc of
        Doc attrs ->
            Just attrs.file

        IPFS attrs ->
            attrs.file


fileSize : Doc -> Maybe Int
fileSize doc =
    case doc of
        Doc attrs ->
            Just attrs.file.size

        IPFS attrs ->
            String.toInt attrs.lighthouse.size


encryptionKey : Doc -> Maybe EncryptionKey
encryptionKey doc =
    case doc of
        Doc attrs ->
            attrs.encryptionKey

        IPFS attrs ->
            attrs.encryptionKey


signed : Doc -> Maybe Sign
signed doc =
    case doc of
        Doc attrs ->
            attrs.signed

        IPFS attrs ->
            attrs.signed


name : Doc -> String
name doc =
    case doc of
        Doc attrs ->
            attrs.name

        IPFS attrs ->
            attrs.lighthouse.name


lighthouse : Doc -> Maybe Lighthouse
lighthouse doc =
    case doc of
        Doc attrs ->
            Nothing

        IPFS attrs ->
            Just attrs.lighthouse
