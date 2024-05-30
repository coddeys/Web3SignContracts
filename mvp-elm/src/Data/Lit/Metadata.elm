module Data.Lit.Metadata exposing (Metadata, addresses, decoder)

import Data.MetaMask.Address as Address exposing (Address)
import Json.Decode


type alias Metadata =
    { chain : String
    , encryptedSymmetricKey : String
    , name : String
    , size : Int
    , type_ : String
    , cid : String
    , accessControlConditions : List AccessControlCondition
    }


decoder : Json.Decode.Decoder Metadata
decoder =
    Json.Decode.map7 Metadata
        (Json.Decode.field "chain" Json.Decode.string)
        (Json.Decode.field "encryptedSymmetricKey" Json.Decode.string)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "size" Json.Decode.int)
        (Json.Decode.field "type" Json.Decode.string)
        (Json.Decode.field "cid" Json.Decode.string)
        (Json.Decode.oneOf
            [ Json.Decode.field "accessControlConditions"
                (Json.Decode.list accessControlConditionDecoder)
            , Json.Decode.succeed []
            ]
        )


decodeAddresses : Json.Decode.Decoder (List Address)
decodeAddresses =
    Json.Decode.list Address.decoder


addresses : Metadata -> List Address
addresses metadata =
    metadata.accessControlConditions
        |> List.map .contractAddress


type alias AccessControlCondition =
    { chain : String
    , contractAddress : Address
    , method : String
    , parameters : List String
    , returnValueTest : AccessControlConditionReturnValueTest
    , standardContractType : String
    }


type alias AccessControlConditionReturnValueTest =
    { comparator : String
    , value : String
    }


accessControlConditionDecoder : Json.Decode.Decoder AccessControlCondition
accessControlConditionDecoder =
    Json.Decode.map6 AccessControlCondition
        (Json.Decode.field "chain" Json.Decode.string)
        (Json.Decode.field "contractAddress" Address.decoder)
        (Json.Decode.field "method" Json.Decode.string)
        (Json.Decode.field "parameters" <| Json.Decode.list Json.Decode.string)
        (Json.Decode.field "returnValueTest" accessControlConditionReturnValueTestDecoder)
        (Json.Decode.field "standardContractType" Json.Decode.string)


accessControlConditionReturnValueTestDecoder : Json.Decode.Decoder AccessControlConditionReturnValueTest
accessControlConditionReturnValueTestDecoder =
    Json.Decode.map2 AccessControlConditionReturnValueTest
        (Json.Decode.field "comparator" Json.Decode.string)
        (Json.Decode.field "value" Json.Decode.string)
