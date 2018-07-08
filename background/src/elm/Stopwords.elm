module Stopwords exposing (words)

import String exposing (join)


words : String
words =
    join "|"
        [ "facebook"
        , "twitter"
        , "はてなブックマーク"
        , "はてブ"
        , "現在"
        , "いいね"
        , "お問い合わせ"
        , "レポート"
        , "テクノロジー"
        , "プログラミング"
        , "スマートフォンアプリ開発"
        , "Webデザイン"
        , "Webマーケティング"
        , "Webディレクション"
        , "status"
        , "project"
        , "constraint"
        , "version"
        , "revision"
        ]
