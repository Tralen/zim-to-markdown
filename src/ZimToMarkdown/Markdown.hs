-- | Conversion from Markdown to Zim wiki markup.
module ZimToMarkdown.Markdown (
    convertMarkdownToZim,
) where

import Control.Applicative ((<|>))
import Data.Char (isDigit)
import Data.Maybe (isNothing)
import Data.Text (Text)
import Data.Text qualified as Text
import System.FilePath (
    dropExtension,
    isAbsolute,
    joinPath,
    normalise,
    splitDirectories,
    takeExtension,
 )

import ZimToMarkdown.Domain (MarkdownDocument (..), ZimPage (..))
import ZimToMarkdown.Inline (
    breakOnFirstMarker,
    enclosed,
    italicBoundary,
 )
import ZimToMarkdown.Links (isExternalTarget)
import ZimToMarkdown.Table (
    isTableStart,
    normalizeTable,
    takeTableBlock,
 )

-- | Converts a Markdown document into a Zim page.
convertMarkdownToZim :: MarkdownDocument -> ZimPage
convertMarkdownToZim (MarkdownDocument content) =
    ZimPage
        ( Text.intercalate
            "\n"
            (renderBlocks (Text.splitOn "\n" (normalizeNewlines content)))
        )

normalizeNewlines :: Text -> Text
normalizeNewlines =
    Text.replace "\r" "\n" . Text.replace "\r\n" "\n"

data Fence = Fence
    { fenceCharacter :: Char
    , fenceLength :: Int
    }

renderBlocks :: [Text] -> [Text]
renderBlocks = go Nothing
  where
    go _ [] = []
    go (Just fence) (line : rest)
        | isClosingFence fence line =
            "'''" : go Nothing rest
        | otherwise =
            line : go (Just fence) rest
    go Nothing (line : underline : rest)
        | Just level <- setextLevel underline
        , isParagraphLine line =
            let zimLevel = min level 5
                marker = Text.replicate (7 - zimLevel) "="
             in ( marker
                    <> " "
                    <> convertInline (Text.strip line)
                    <> " "
                    <> marker
                )
                    : go Nothing rest
    go Nothing (line : rest)
        | Just fence <- openingFence line =
            "'''" : go (Just fence) rest
        | isTableStart line =
            let (block, remaining) = takeTableBlock (line : rest)
             in normalizeTable block <> go Nothing remaining
        | otherwise =
            renderLine line : go Nothing rest

setextLevel :: Text -> Maybe Int
setextLevel line =
    let trimmed = Text.strip line
     in if not (Text.null trimmed) && Text.all (== '=') trimmed
            then Just 1
            else
                if not (Text.null trimmed) && Text.all (== '-') trimmed
                    then Just 2
                    else Nothing

isParagraphLine :: Text -> Bool
isParagraphLine line =
    not (Text.null (Text.strip line))
        && isNothing (parseHeading line)
        && isNothing (parseListLine line)
        && isNothing (parseBlockquote line)
        && isNothing (openingFence line)
        && not (isTableStart line)
        && not (isThematicBreak line)

openingFence :: Text -> Maybe Fence
openingFence line =
    let stripped = Text.stripStart line
     in case Text.uncons stripped of
            Just (character, rest)
                | character == '`' || character == '~' ->
                    let count =
                            1 + Text.length (Text.takeWhile (== character) rest)
                     in if count >= 3
                            then Just (Fence character count)
                            else Nothing
            _ -> Nothing

isClosingFence :: Fence -> Text -> Bool
isClosingFence fence line =
    let trimmed = Text.strip line
        run =
            Text.length
                (Text.takeWhile (== fenceCharacter fence) trimmed)
     in run >= fenceLength fence
            && Text.length trimmed == run

renderLine :: Text -> Text
renderLine line
    | isThematicBreak line = "-----"
    | Just (depth, content) <- parseBlockquote line =
        Text.replicate depth "\t" <> renderLine content
    | Just (level, content) <- parseHeading line =
        let zimLevel = min level 5
            marker = Text.replicate (7 - zimLevel) "="
         in marker <> " " <> convertInline content <> " " <> marker
    | Just listLine <- parseListLine line =
        renderListLine listLine
    | otherwise = convertInline line

isThematicBreak :: Text -> Bool
isThematicBreak line =
    case Text.uncons stripped of
        Nothing -> False
        Just (marker, rest) ->
            Text.length stripped >= 3
                && Text.all (== marker) rest
                && marker `elem` ['-', '*', '_']
  where
    stripped = Text.filter (/= ' ') (Text.strip line)

parseBlockquote :: Text -> Maybe (Int, Text)
parseBlockquote line =
    let (depth, content) = countQuotes 0 (Text.stripStart line)
     in if depth == 0
            then Nothing
            else Just (depth, content)
  where
    countQuotes depth text =
        case Text.stripPrefix ">" text of
            Nothing -> (depth, text)
            Just after ->
                let rest = Text.dropWhile (== ' ') after
                 in countQuotes (depth + 1) rest

parseHeading :: Text -> Maybe (Int, Text)
parseHeading line =
    let stripped = Text.stripStart line
        hashes = Text.takeWhile (== '#') stripped
        level = Text.length hashes
        after = Text.drop level stripped
     in if level >= 1
            && level <= 6
            && (Text.null after || Text.isPrefixOf " " after)
            then
                let content = stripClosingHashes (Text.strip after)
                 in if Text.null content
                        then Nothing
                        else Just (level, content)
            else Nothing

stripClosingHashes :: Text -> Text
stripClosingHashes text =
    let trimmed = Text.stripEnd text
        hashes = Text.takeWhileEnd (== '#') trimmed
        body = Text.dropEnd (Text.length hashes) trimmed
     in if Text.null hashes || Text.null (Text.stripEnd body)
            then trimmed
            else Text.stripEnd body

data MarkdownListMarker
    = Bullet
    | Task Bool
    | Numbered
    deriving (Eq)

data MarkdownListLine = MarkdownListLine
    { markdownListIndent :: Text
    , markdownListMarker :: MarkdownListMarker
    , markdownListContent :: Text
    }

parseListLine :: Text -> Maybe MarkdownListLine
parseListLine line =
    let (indent, rest) = Text.span isIndent line
     in case parseMarker rest of
            Nothing -> Nothing
            Just (marker, content) ->
                Just
                    MarkdownListLine
                        { markdownListIndent = indent
                        , markdownListMarker = marker
                        , markdownListContent = content
                        }
  where
    isIndent character = character == ' ' || character == '\t'

parseMarker :: Text -> Maybe (MarkdownListMarker, Text)
parseMarker text
    | Just rest <- Text.stripPrefix "- [ ] " text = Just (Task False, rest)
    | Just rest <- Text.stripPrefix "* [ ] " text = Just (Task False, rest)
    | Just rest <- Text.stripPrefix "+ [ ] " text = Just (Task False, rest)
    | Just rest <- taskChecked "-" text = Just (Task True, rest)
    | Just rest <- taskChecked "*" text = Just (Task True, rest)
    | Just rest <- taskChecked "+" text = Just (Task True, rest)
    | Just rest <- Text.stripPrefix "- " text = Just (Bullet, rest)
    | Just rest <- Text.stripPrefix "* " text = Just (Bullet, rest)
    | Just rest <- Text.stripPrefix "+ " text = Just (Bullet, rest)
    | otherwise = parseNumbered text

taskChecked :: Text -> Text -> Maybe Text
taskChecked bullet text =
    let afterBullet = Text.stripPrefix bullet text
     in case afterBullet of
            Just rest ->
                Text.stripPrefix " [x] " rest <|> Text.stripPrefix " [X] " rest
            Nothing -> Nothing

parseNumbered :: Text -> Maybe (MarkdownListMarker, Text)
parseNumbered text =
    let (digits, afterDigits) = Text.span isDigit text
     in if Text.null digits
            then Nothing
            else case Text.stripPrefix ". " afterDigits
                <|> Text.stripPrefix ") " afterDigits of
                Just rest -> Just (Numbered, rest)
                Nothing -> Nothing

renderListLine :: MarkdownListLine -> Text
renderListLine listLine =
    indentToTabs (markdownListIndent listLine)
        <> prefix
        <> convertInline (markdownListContent listLine)
  where
    prefix =
        case markdownListMarker listLine of
            Bullet -> "* "
            Task False -> "[ ] "
            Task True -> "[*] "
            Numbered -> "1. "

indentToTabs :: Text -> Text
indentToTabs indent =
    let (spaces, rest) = Text.span (== ' ') indent
        tabs = Text.replicate (Text.length spaces `div` 2) "\t"
        leftover = Text.replicate (Text.length spaces `mod` 2) " "
     in tabs <> leftover <> rest

inlineMarkers :: [Text]
inlineMarkers =
    [ "!["
    , "["
    , "<a "
    , "<strong>"
    , "<b>"
    , "<em>"
    , "<i>"
    , "<mark>"
    , "<u>"
    , "<sub>"
    , "<sup>"
    , "<"
    , "**"
    , "__"
    , "~~"
    , "`"
    , "*"
    , "_"
    ]

convertInline :: Text -> Text
convertInline = go
  where
    go text =
        let (plain, marker) = breakOnFirstMarker inlineMarkers text
         in plain
                <> case marker of
                    Nothing -> ""
                    Just suffix -> convertMarker plain suffix

    convertMarker preceding text
        | Just result <- convertImage text = keep result
        | Just result <- convertLink text = keep result
        | Just result <- convertAnchor text = keep result
        | Just result <-
            enclosed "<strong>" "</strong>" (\inner -> "**" <> go inner <> "**") text =
            keep result
        | Just result <-
            enclosed "<b>" "</b>" (\inner -> "**" <> go inner <> "**") text =
            keep result
        | Just result <-
            enclosed "<em>" "</em>" (\inner -> "//" <> go inner <> "//") text =
            keep result
        | Just result <-
            enclosed "<i>" "</i>" (\inner -> "//" <> go inner <> "//") text =
            keep result
        | Just result <-
            enclosed "<mark>" "</mark>" (\inner -> "__" <> go inner <> "__") text =
            keep result
        | Just result <-
            enclosed "<u>" "</u>" (\inner -> "__" <> go inner <> "__") text =
            keep result
        | Just result <-
            enclosed "<sub>" "</sub>" (\inner -> "_{" <> go inner <> "}") text =
            keep result
        | Just result <-
            enclosed "<sup>" "</sup>" (\inner -> "^{" <> go inner <> "}") text =
            keep result
        | Just result <- convertAutolink text = keep result
        | Just result <-
            enclosed "**" "**" (\inner -> "**" <> go inner <> "**") text =
            keep result
        | Just result <-
            enclosed "__" "__" (\inner -> "**" <> go inner <> "**") text =
            keep result
        | Just result <-
            enclosed "~~" "~~" (\inner -> "~~" <> go inner <> "~~") text =
            keep result
        | Just result <- convertCode text = keep result
        | italicBoundary preceding
        , Just result <-
            enclosed "*" "*" (\inner -> "//" <> go inner <> "//") text =
            keep result
        | italicBoundary preceding
        , Just result <-
            enclosed "_" "_" (\inner -> "//" <> go inner <> "//") text =
            keep result
        | otherwise = Text.take 1 text <> go (Text.drop 1 text)

    keep (rendered, after) = rendered <> go after

convertImage :: Text -> Maybe (Text, Text)
convertImage text = do
    rest <- Text.stripPrefix "![" text
    let (alt, afterAlt) = Text.breakOn "](" rest
    afterOpen <- Text.stripPrefix "](" afterAlt
    let (target, afterTarget) = Text.breakOn ")" afterOpen
    if Text.null afterTarget
        then Nothing
        else
            let path = Text.strip target
                display = Text.strip alt
             in if Text.null path
                    then Nothing
                    else
                        let rendered =
                                "{{"
                                    <> path
                                    <> ( if Text.null display
                                            then ""
                                            else "|" <> display
                                       )
                                    <> "}}"
                         in Just (rendered, Text.drop 1 afterTarget)

convertAnchor :: Text -> Maybe (Text, Text)
convertAnchor text = do
    rest <- Text.stripPrefix "<a id=\"" text
    let (name, afterName) = Text.breakOn "\"" rest
    afterClose <- Text.stripPrefix "\"></a>" afterName
    if Text.null name
        then Nothing
        else Just ("{{id: " <> name <> "}}", afterClose)

convertAutolink :: Text -> Maybe (Text, Text)
convertAutolink text = do
    rest <- Text.stripPrefix "<" text
    let (inner, after) = Text.breakOn ">" rest
    if Text.null after
        then Nothing
        else
            let target = Text.strip inner
             in if isExternalTarget target
                    then Just ("[[" <> target <> "]]", Text.drop 1 after)
                    else Nothing

convertLink :: Text -> Maybe (Text, Text)
convertLink text = do
    rest <- Text.stripPrefix "[" text
    let (label, afterLabel) = Text.breakOn "](" rest
    afterOpen <- Text.stripPrefix "](" afterLabel
    let (target, afterTarget) = Text.breakOn ")" afterOpen
    if Text.null afterTarget
        then Nothing
        else
            let display = convertInline (Text.strip label)
                zimTarget = markdownTarget (Text.strip target)
             in if Text.null zimTarget
                    then Nothing
                    else
                        let rendered =
                                if Text.null display || display == zimTarget
                                    then "[[" <> zimTarget <> "]]"
                                    else
                                        "[["
                                            <> zimTarget
                                            <> "|"
                                            <> display
                                            <> "]]"
                         in Just (rendered, Text.drop 1 afterTarget)

markdownTarget :: Text -> Text
markdownTarget rawTarget =
    let target = stripAngleBrackets rawTarget
        (pathPart, anchor) = Text.breakOn "#" target
     in convertPath (Text.strip pathPart) <> anchor

stripAngleBrackets :: Text -> Text
stripAngleBrackets target
    | Text.isPrefixOf "<" target && Text.isSuffixOf ">" target =
        Text.dropEnd 1 (Text.drop 1 target)
    | otherwise = target

convertPath :: Text -> Text
convertPath path
    | Text.null path = path
    | isExternalTarget path = path
    | extension `elem` [".md", ".markdown", ".txt"] =
        Text.pack (zimPath (dropExtension (Text.unpack path)))
    | otherwise = path
  where
    extension =
        Text.toLower (Text.pack (takeExtension (Text.unpack path)))

zimPath :: FilePath -> FilePath
zimPath path =
    let parts = splitDirectories (normalise path)
        cleaned =
            if isAbsolute path
                then dropWhile (== "/") parts
                else dropWhile (\part -> part == "." || part == "..") parts
        joined = joinPath cleaned
     in if isAbsolute path then ':' : joined else joined

convertCode :: Text -> Maybe (Text, Text)
convertCode text =
    let (ticks, rest) = Text.span (== '`') text
        count = Text.length ticks
     in if count == 0
            then Nothing
            else
                let (inner, closing) = Text.breakOn ticks rest
                 in if Text.null inner || Text.null closing
                        then Nothing
                        else
                            Just
                                ( "''" <> normalizeCodeContent inner <> "''"
                                , Text.drop count closing
                                )

normalizeCodeContent :: Text -> Text
normalizeCodeContent content
    | Text.length content >= 2
    , Text.isPrefixOf " " content
    , Text.isSuffixOf " " content
    , not (Text.all (== ' ') content) =
        Text.dropEnd 1 (Text.drop 1 content)
    | otherwise = content
