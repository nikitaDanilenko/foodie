module Api.Types.ReferenceTree exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.ReferenceMap exposing (..)
import Api.Types.ReferenceValue exposing (..)

type alias ReferenceTree = { referenceMap: ReferenceMap, nutrients: (List ReferenceValue) }


decoderReferenceTree : Decode.Decoder ReferenceTree
decoderReferenceTree = Decode.succeed ReferenceTree |> required "referenceMap" (Decode.lazy (\_ -> decoderReferenceMap)) |> required "nutrients" (Decode.list (Decode.lazy (\_ -> decoderReferenceValue)))


encoderReferenceTree : ReferenceTree -> Encode.Value
encoderReferenceTree obj = Encode.object [ ("referenceMap", encoderReferenceMap obj.referenceMap), ("nutrients", Encode.list encoderReferenceValue obj.nutrients) ]