module NGram exposing (..)

import Regex
import String exposing (toList, fromList, join, toLower, length)
import List exposing (head, member, drop, foldl)
import List.Extra exposing (unique)
import Regex exposing (replace, HowMany, regex)


tokeinze : String -> List String
tokeinze line =
    let
        text =
            line
                |> toLower
                |> replace Regex.All (Regex.regex "\x3000+") (\_ -> " ")
                |> replace Regex.All (Regex.regex " +") (\_ -> " ")
    in
        if member text stopWords || length text <= 1 then
            []
        else
            (case toList text of
                x :: xx :: xxx :: _ ->
                    if (charHeadFilter [ x ]) || (fromList [ x, xx, xxx ] |> regexFilter) then
                        []
                    else
                        [ fromList [ x, xx, xxx ] ]

                _ ->
                    []
            )
                ++ (case toList text of
                        x :: xs ->
                            xs
                                |> fromList
                                |> tokeinze

                        _ ->
                            []
                   )
                |> unique


charHeadFilter : List Char -> Bool
charHeadFilter chars =
    case head chars of
        Just xs ->
            member (fromList [ xs ]) filterChars

        Nothing ->
            False


regexFilter : String -> Bool
regexFilter chars =
    Regex.contains regex chars


regex : Regex.Regex
regex =
    "[" ++ Regex.escape " ・〜一「」①-⑨【】、。!\\\"#$%&'()*+-.,/:;<=>?@[]^_`{|}~" ++ "0-9]" |> Regex.regex


filterChars : List String
filterChars =
    [ "で"
    , "を"
    , "ん"
    , "の"
    , "っ"
    , "に"
    , "は"
    , " "
    , "\x3000"
    ]


stopWords : List String
stopWords =
    [ "myself"
    , "our"
    , "ours"
    , "ourselves"
    , "you"
    , "your"
    , "yours"
    , "yourself"
    , "yourselves"
    , "him"
    , "his"
    , "himself"
    , "she"
    , "her"
    , "hers"
    , "herself"
    , "its"
    , "itself"
    , "they"
    , "them"
    , "their"
    , "theirs"
    , "themselves"
    , "what"
    , "which"
    , "who"
    , "whom"
    , "this"
    , "that"
    , "these"
    , "those"
    , "are"
    , "was"
    , "were"
    , "been"
    , "being"
    , "have"
    , "has"
    , "had"
    , "having"
    , "does"
    , "did"
    , "doing"
    , "the"
    , "and"
    , "but"
    , "because"
    , "until"
    , "while"
    , "for"
    , "with"
    , "about"
    , "against"
    , "between"
    , "into"
    , "through"
    , "during"
    , "before"
    , "after"
    , "above"
    , "below"
    , "from"
    , "down"
    , "out"
    , "off"
    , "over"
    , "under"
    , "again"
    , "further"
    , "then"
    , "once"
    , "here"
    , "there"
    , "when"
    , "where"
    , "why"
    , "how"
    , "all"
    , "any"
    , "both"
    , "each"
    , "few"
    , "more"
    , "most"
    , "other"
    , "some"
    , "such"
    , "nor"
    , "not"
    , "only"
    , "own"
    , "same"
    , "than"
    , "too"
    , "very"
    , "can"
    , "will"
    , "just"
    , "don"
    , "should"
    , "now"
    ]
