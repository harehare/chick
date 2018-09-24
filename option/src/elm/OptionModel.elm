module OptionModel exposing (..)

import Http
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
    | DataImport
    | Export
    | Import
    | InputTag IndexInfo
    | EditTag String
    | AddTag IndexInfo
    | RemoveTag IndexInfo String
    | SearchTag String
    | SelectText String
    | UpdateStatus IndexStatus
    | OptionTokenizeNGram String
    | OptionSearchResult (List Item)
    | CallSearchApi ( String, String )
    | Bookmark IndexInfo
    | VerifySearchApi
    | ResponseSearchApi (Result Http.Error (List Item))
    | SearchApiResult (Result Http.Error (List Item))


type Api
    = Scraping
    | QueryParse
    | Scoring


type alias IndexStatus =
    { documentCount : Int
    , indexedCount : Int
    }


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
    , logoUrl : String
    , inputTag : String
    }


type alias IndexInfo =
    { url : String
    , bookmark : Bool
    , tags : List String
    , isInputting : Bool
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
