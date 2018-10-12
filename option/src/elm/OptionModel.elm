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
    | ChangeTag Bool String String
    | Reindexing
    | DataImport
    | Export
    | Import
    | InputTag IndexInfo
    | EditTag String
    | AddTag IndexInfo
    | SearchTag String
    | SelectText String
    | UpdateStatus IndexStatus
    | OptionTokenizeNGram String
    | OptionSearchResult (List Item)
    | Bookmark IndexInfo


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
    , isIndexing : Bool
    , status : IndexStatus
    , deleteUrlList : List String
    , indexInfo : List IndexInfo
    , logoUrl : String
    , inputTag : String
    , tags : List String
    }


type alias IndexInfo =
    { url : String
    , bookmark : Bool
    , tags : List String
    , isInputting : Bool
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
