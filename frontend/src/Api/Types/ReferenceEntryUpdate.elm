module Api.Types.ReferenceEntryUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias ReferenceEntryUpdate = { referenceMapId: UUID, nutrientCode: Int, amount: Float }


decoderReferenceEntryUpdate : Decode.Decoder ReferenceEntryUpdate
decoderReferenceEntryUpdate = Decode.succeed ReferenceEntryUpdate |> required "referenceMapId" decoderUUID |> required "nutrientCode" Decode.int |> required "amount" Decode.float


encoderReferenceEntryUpdate : ReferenceEntryUpdate -> Encode.Value
encoderReferenceEntryUpdate obj = Encode.object [ ("referenceMapId", encoderUUID obj.referenceMapId), ("nutrientCode", Encode.int obj.nutrientCode), ("amount", Encode.float obj.amount) ]