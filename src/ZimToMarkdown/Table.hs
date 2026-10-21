-- | Pipe table detection and normalization for both conversion directions.
module ZimToMarkdown.Table
    ( isTableStart
    , normalizeTable
    , takeTableBlock
    ) where

import Data.Text (Text)
import qualified Data.Text as Text

-- | Tests whether a line can start a pipe table.
isTableStart :: Text -> Bool
isTableStart = isTableRow

-- | Splits a table into its header, optional alignment line, and body rows.
takeTableBlock :: [Text] -> ([Text], [Text])
takeTableBlock [] = ([], [])
takeTableBlock (header : rest)
    | not (isTableRow header) = ([], header : rest)
    | otherwise =
        let (alignment, afterAlignment) =
                case rest of
                    (candidate : more)
                        | isAlignmentLine candidate ->
                            ([candidate], more)
                    _ -> ([], rest)
            (body, remaining) = span isTableRow afterAlignment
        in (header : alignment <> body, remaining)

-- | Normalizes a Zim or Markdown table into a portable pipe table.
normalizeTable :: [Text] -> [Text]
normalizeTable [] = []
normalizeTable (headerLine : rest) =
    let headerCells = map stripHeaderWrap (parseTableCells headerLine)
        (alignmentCells, bodyLines) =
            case rest of
                (candidate : more)
                    | isAlignmentLine candidate ->
                        (parseTableCells candidate, more)
                _ -> ([], rest)
        bodyCells = map parseTableCells bodyLines
        width =
            maximum
                (length headerCells : map length bodyCells)
        paddedHeader = padTo width headerCells
        paddedAlignment =
            take width
                (map normalizeAlignmentCell alignmentCells <> repeat "---")
        paddedBody = map (padTo width) bodyCells
    in renderTableRow paddedHeader
        : renderTableRow paddedAlignment
        : map renderTableRow paddedBody

isTableRow :: Text -> Bool
isTableRow line =
    let trimmed = Text.strip line
    in Text.length trimmed >= 2
        && Text.isPrefixOf "|" trimmed
        && Text.isSuffixOf "|" trimmed

isAlignmentLine :: Text -> Bool
isAlignmentLine line =
    isTableRow line
        && all isAlignmentCell (parseTableCells line)

isAlignmentCell :: Text -> Bool
isAlignmentCell cell =
    let trimmed = Text.strip cell
    in not (Text.null trimmed)
        && Text.all (\character -> character == '-' || character == ':' || character == ' ') trimmed
        && Text.any (== '-') trimmed

parseTableCells :: Text -> [Text]
parseTableCells line =
    let trimmed = Text.strip line
        inner = Text.dropEnd 1 (Text.drop 1 trimmed)
    in splitUnescaped '|' inner

splitUnescaped :: Char -> Text -> [Text]
splitUnescaped delimiter = go [] []
  where
    go current acc text =
        case Text.uncons text of
            Nothing ->
                reverse (Text.pack (reverse current) : acc)
            Just ('\\', rest) ->
                case Text.uncons rest of
                    Just (character, more) ->
                        go (character : '\\' : current) acc more
                    Nothing ->
                        reverse
                            ( Text.pack (reverse ('\\' : current)) : acc
                            )
            Just (character, rest)
                | character == delimiter ->
                    go [] (Text.pack (reverse current) : acc) rest
                | otherwise ->
                    go (character : current) acc rest

normalizeAlignmentCell :: Text -> Text
normalizeAlignmentCell cell =
    let trimmed = Text.strip cell
        alignedLeft = Text.isPrefixOf ":" trimmed
        alignedRight = Text.isSuffixOf ":" trimmed
    in (if alignedLeft then ":" else "")
        <> "---"
        <> (if alignedRight then ":" else "")

stripHeaderWrap :: Text -> Text
stripHeaderWrap cell =
    Text.stripEnd (Text.dropWhileEnd (== '<') (Text.strip cell))

padTo :: Int -> [Text] -> [Text]
padTo width cells = take width (map Text.strip cells <> repeat "")

renderTableRow :: [Text] -> Text
renderTableRow cells =
    "| " <> Text.intercalate " | " cells <> " |"
