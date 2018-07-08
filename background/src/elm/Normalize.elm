module Normalize exposing (normalize)

import Native.Normalize


normalize : String -> String
normalize str =
    Native.Normalize.normalize str
