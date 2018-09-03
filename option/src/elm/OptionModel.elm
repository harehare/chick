module OptionModel exposing (..)

import Http
import PopupModel exposing (IndexStatus)
import Model exposing (Item)


type Msg
    = NoOp
    | EditBlockKeyword String
    | EditSearchQuery String
    | DeleteBlockKeyword String
    | DeleteItem String
    | AddBlockList
    | ChangeViewOption String
    | ChangeIndexTarget String
    | Save
    | Reindexing
    | EditApiUrl String
    | DeleteIndex
    | ImportPocket
    | Export
    | Import
    | SelectText String
    | UpdateStatus IndexStatus
    | OptionTokenizeNGram String
    | OptionSearchResult (List Item)
    | Bookmark IndexInfo
    | VerifySearchApi
    | ResponseSearchApi (Result Http.Error (List Item))


type Api
    = Scraping
    | QueryParse
    | Scoring


type alias Model =
    { viewOption : ViewOption
    , blockList : List String
    , blockKeyword : String
    , query : String
    , searchResult : List Item
    , indexTarget : IndexTarget
    , changed : Bool
    , isIndexing : Bool
    , status : IndexStatus
    , deleteUrlList : List String
    , indexInfo : List IndexInfo
    , searchApi : ApiStatus
    }


type alias IndexInfo =
    { url : String
    , bookmark : Bool
    }


type alias ApiStatus =
    { verify : Bool
    , url : String
    }


type alias ViewOption =
    { google : Bool
    , bing : Bool
    , duckDuckGo : Bool
    , yahoo : Bool
    }


type alias IndexTarget =
    { bookmark : Bool
    , history : Bool
    , pocket : Bool
    }
