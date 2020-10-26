module Api.Source exposing (Source, decoder)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E


type alias Source =
    { name : String
    , url : String
    }


decoder : D.Decoder Source
decoder =
    D.succeed Source
        |> required "name" D.string
        |> required "url" D.string
