module Api.Datapoint exposing (Datapoint, decoder, list_decoder)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E


type alias Datapoint =
    { slice : Int
    , value : Int
    }


decoder : D.Decoder Datapoint
decoder =
    D.succeed Datapoint
        |> required "slice" D.int
        |> required "value" D.int


list_decoder : D.Decoder (List Datapoint)
list_decoder =
    D.list decoder
