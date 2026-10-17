module ZimToMarkdown.Inline
    ( breakOnFirstMarker
    , enclosed
    , italicBoundary
    , renderInlineCode
    , renderMarkdownPath
    ) where

import Data.Char (isSpace)
import Data.List (minimumBy)
import Data.Ord (comparing)
import Data.Text (Text)
import qualified Data.Text as Text

-- | Finds the earliest occurrence of any marker and returns the text before it
-- together with the remaining text, which starts with the marker.
breakOnFirstMarker :: [Text] -> Text -> (Text, Maybe Text)
breakOnFirstMarker markers text =
    case
        [ (Text.length prefix, suffix)
        | marker <- markers
        , let (prefix, suffix) = Text.breakOn marker text
        , not (Text.null suffix)
        ] of
        [] -> (text, Nothing)
        matches ->
            let (index, suffix) = minimumBy (comparing fst) matches
            in (Text.take index text, Just suffix)

-- | Splits text that starts with an opening delimiter and contains a closing
-- delimiter, returning the rendered content and the remaining text.
enclosed :: Text -> Text -> (Text -> Text) -> Text -> Maybe (Text, Text)
enclosed opener closer render text = do
    rest <- Text.stripPrefix opener text
    let (inner, closing) = Text.breakOn closer rest
    if Text.null inner || Text.null closing
        then Nothing
        else
            Just
                ( render inner
                , Text.drop (Text.length closer) closing
                )

-- | Tests whether an opening delimiter can start inline emphasis. This keeps
-- constructs such as URLs and identifiers with underscores intact.
italicBoundary :: Text -> Bool
italicBoundary preceding =
    case Text.unsnoc preceding of
        Nothing -> True
        Just (_, character) ->
            isSpace character || character `elem` ("([{<'\"-" :: String)

-- | Renders inline code with a backtick fence long enough to hold its content.
renderInlineCode :: Text -> Text
renderInlineCode content =
    let fence = Text.replicate (longestBacktickRun content + 1) "`"
        padded
            | Text.isPrefixOf "`" content || Text.isSuffixOf "`" content =
                " " <> content <> " "
            | otherwise = content
    in fence <> padded <> fence

-- | Renders a link target, wrapping it in angle brackets when it contains
-- characters that would break a Markdown destination.
renderMarkdownPath :: Text -> Text
renderMarkdownPath path
    | Text.null path = path
    | Text.any needsBrackets path = "<" <> path <> ">"
    | otherwise = path
  where
    needsBrackets character =
        character == ' ' || character == '(' || character == ')'

longestBacktickRun :: Text -> Int
longestBacktickRun = snd . Text.foldl' step (0, 0)
  where
    step (current, longest) character
        | character == '`' =
            let next = current + 1
            in (next, max longest next)
        | otherwise = (0, longest)
