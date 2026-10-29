-- | Conversion from Zim wiki markup to Markdown.
module ZimToMarkdown.Zim (
    convertZimToMarkdown,
    convertZimToMarkdownWithAssets,
    zimImagePaths,
) where

import Data.Char (isAlpha, isDigit)
import Data.List (nub, sort)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as Text
import System.FilePath (takeBaseName)

import ZimToMarkdown.Domain (MarkdownDocument (..), ZimPage (..))
import ZimToMarkdown.Inline (
    breakOnFirstMarker,
    enclosed,
    italicBoundary,
    renderInlineCode,
    renderMarkdownPath,
 )
import ZimToMarkdown.Links (LinkContext, renderZimLink)
import ZimToMarkdown.Table (
    isTableStart,
    normalizeTable,
    takeTableBlock,
 )

-- | Converts a Zim page into Markdown.
convertZimToMarkdown :: LinkContext -> ZimPage -> MarkdownDocument
convertZimToMarkdown context =
    convertZimToMarkdownWithAssets context Map.empty

{- | Converts a Zim page into Markdown, rewriting images to the targets the
notebook conversion prepared for them.
-}
convertZimToMarkdownWithAssets ::
    LinkContext ->
    Map.Map Text Text ->
    ZimPage ->
    MarkdownDocument
convertZimToMarkdownWithAssets context assets (ZimPage content) =
    let lines =
            Text.splitOn
                "\n"
                (stripZimHeader (normalizeNewlines content))
        headingMap = buildHeadingMap lines
     in MarkdownDocument
            ( Text.intercalate
                "\n"
                (renderBlocks context assets headingMap lines)
            )

stripZimHeader :: Text -> Text
stripZimHeader content =
    let lines = Text.splitOn "\n" content
        remaining = dropWhile isMetadataLine lines
     in if length remaining == length lines
            then content
            else Text.intercalate "\n" (dropWhile isBlank remaining)

isMetadataLine :: Text -> Bool
isMetadataLine line =
    let key = Text.toLower (Text.strip (fst (Text.breakOn ":" line)))
     in key `elem` metadataKeys

metadataKeys :: [Text]
metadataKeys =
    [ "content-type"
    , "wiki-format"
    , "creation-date"
    , "modification-date"
    ]

isBlank :: Text -> Bool
isBlank = Text.null . Text.strip

{- | Compresses the heading levels present in a page into consecutive
Markdown levels starting at one.
-}
buildHeadingMap :: [Text] -> Map.Map Int Int
buildHeadingMap lines =
    Map.fromList
        (zip (sort (nub (collectHeadingLevels lines))) [1 ..])

collectHeadingLevels :: [Text] -> [Int]
collectHeadingLevels = go OutsideVerbatim
  where
    go _ [] = []
    go state (line : rest)
        | isVerbatimDelimiter line = go (toggleState state) rest
        | state == InsideVerbatim = go InsideVerbatim rest
        | Just (level, _) <- parseHeading line =
            level : go OutsideVerbatim rest
        | otherwise = go OutsideVerbatim rest

normalizeNewlines :: Text -> Text
normalizeNewlines =
    Text.replace "\r" "\n" . Text.replace "\r\n" "\n"

data BlockState
    = OutsideVerbatim
    | InsideVerbatim
    deriving (Eq)

renderBlocks :: LinkContext -> Map.Map Text Text -> Map.Map Int Int -> [Text] -> [Text]
renderBlocks context assets headingMap = go OutsideVerbatim
  where
    go _ [] = []
    go state (line : rest)
        | isVerbatimDelimiter line =
            "```" : go (toggleState state) rest
        | state == InsideVerbatim =
            line : go InsideVerbatim rest
        | isTableStart line =
            let (block, remaining) = takeTableBlock (line : rest)
             in normalizeTable block <> go OutsideVerbatim remaining
        | otherwise =
            renderLine context assets headingMap line : go OutsideVerbatim rest

toggleState :: BlockState -> BlockState
toggleState OutsideVerbatim = InsideVerbatim
toggleState InsideVerbatim = OutsideVerbatim

isVerbatimDelimiter :: Text -> Bool
isVerbatimDelimiter line = Text.strip line == "'''"

renderLine :: LinkContext -> Map.Map Text Text -> Map.Map Int Int -> Text -> Text
renderLine context assets headingMap line
    | Text.null (Text.strip line) = line
    | Just (level, content) <- parseHeading line =
        let markdownLevel =
                min 3 (Map.findWithDefault level level headingMap)
         in Text.replicate markdownLevel "#"
                <> " "
                <> convertInline context assets content
    | isHorizontalRule line = "---"
    | Just listLine <- parseListLine line =
        renderListLine context assets listLine
    | Just (depth, content) <- parseIndentedBlock line =
        Text.replicate depth "> "
            <> renderLine context assets headingMap content
    | otherwise = convertInline context assets line

isHorizontalRule :: Text -> Bool
isHorizontalRule line =
    let trimmed = Text.strip line
     in Text.length trimmed >= 5 && Text.all (== '-') trimmed

parseIndentedBlock :: Text -> Maybe (Int, Text)
parseIndentedBlock line =
    let (tabs, afterTabs) = Text.span (== '\t') line
        (spaces, rest) = Text.span (== ' ') afterTabs
        depth = Text.length tabs + Text.length spaces `div` 4
     in if depth == 0
            then Nothing
            else Just (depth, rest)

parseHeading :: Text -> Maybe (Int, Text)
parseHeading line =
    let opening = Text.takeWhile (== '=') line
        count = Text.length opening
     in if count >= 2 && count <= 6
            then
                let afterOpening = Text.drop count line
                    closing = Text.takeWhileEnd (== '=') afterOpening
                    content =
                        Text.strip
                            (Text.dropEnd (Text.length closing) afterOpening)
                 in if Text.length closing == count && not (Text.null content)
                        then Just (7 - count, content)
                        else Nothing
            else Nothing

data ListMarker
    = Bullet
    | Numbered
    | Alphabetic
    | Task Bool
    deriving (Eq)

data ListLine = ListLine
    { listIndent :: Text
    , listMarker :: ListMarker
    , listContent :: Text
    }

parseListLine :: Text -> Maybe ListLine
parseListLine line =
    let (indent, rest) = Text.span isIndent line
     in case parseMarker rest of
            Nothing -> Nothing
            Just (marker, content) ->
                Just
                    ListLine
                        { listIndent = indent
                        , listMarker = marker
                        , listContent = content
                        }
  where
    isIndent character = character == ' ' || character == '\t'

parseMarker :: Text -> Maybe (ListMarker, Text)
parseMarker text
    | Just rest <- Text.stripPrefix "[ ] " text = Just (Task False, rest)
    | Just rest <- Text.stripPrefix "[*] " text = Just (Task True, rest)
    | Just rest <- Text.stripPrefix "[x] " text = Just (Task True, rest)
    | Just rest <- Text.stripPrefix "[X] " text = Just (Task True, rest)
    | Just rest <- Text.stripPrefix "[>] " text = Just (Task True, rest)
    | Just rest <- Text.stripPrefix "[<] " text = Just (Task True, rest)
    | Just rest <- Text.stripPrefix "* " text = Just (Bullet, rest)
    | Just rest <- Text.stripPrefix "- " text = Just (Bullet, rest)
    | otherwise = parseOrdered text

parseOrdered :: Text -> Maybe (ListMarker, Text)
parseOrdered text =
    let (digits, afterDigits) = Text.span isDigit text
     in if Text.null digits
            then parseAlphabetic text
            else case Text.stripPrefix ". " afterDigits of
                Just rest -> Just (Numbered, rest)
                Nothing -> parseAlphabetic text

parseAlphabetic :: Text -> Maybe (ListMarker, Text)
parseAlphabetic text =
    case Text.uncons text of
        Just (letter, afterLetter)
            | isAlpha letter
            , Just rest <- Text.stripPrefix ". " afterLetter ->
                Just (Alphabetic, rest)
        _ -> Nothing

renderListLine :: LinkContext -> Map.Map Text Text -> ListLine -> Text
renderListLine context assets listLine =
    indentToSpaces (listIndent listLine)
        <> prefix
        <> convertInline context assets (listContent listLine)
  where
    prefix =
        case listMarker listLine of
            Bullet -> "* "
            Numbered -> "1. "
            Alphabetic -> "1. "
            Task False -> "- [ ] "
            Task True -> "- [x] "

indentToSpaces :: Text -> Text
indentToSpaces =
    Text.concatMap
        ( \character ->
            if character == '\t'
                then "  "
                else Text.singleton character
        )

inlineMarkers :: [Text]
inlineMarkers =
    [ "<strong>"
    , "<b>"
    , "<em>"
    , "<i>"
    , "{{id:"
    , "**"
    , "//"
    , "__"
    , "''"
    , "~~"
    , "[["
    , "{{"
    , "_{"
    , "^{"
    ]

convertInline :: LinkContext -> Map.Map Text Text -> Text -> Text
convertInline context assets = go
  where
    go text =
        let (plain, marker) = breakOnFirstMarker inlineMarkers text
         in plain
                <> case marker of
                    Nothing -> ""
                    Just suffix -> convertMarker plain suffix

    convertMarker preceding text
        | Just result <-
            enclosed "<strong>" "</strong>" (\inner -> "**" <> go inner <> "**") text =
            keep result
        | Just result <-
            enclosed "<b>" "</b>" (\inner -> "**" <> go inner <> "**") text =
            keep result
        | Just result <-
            enclosed "<em>" "</em>" (\inner -> "*" <> go inner <> "*") text =
            keep result
        | Just result <-
            enclosed "<i>" "</i>" (\inner -> "*" <> go inner <> "*") text =
            keep result
        | Just result <- enclosed "{{id:" "}}" renderAnchor text =
            keep result
        | Just result <-
            enclosed "**" "**" (\inner -> "**" <> go inner <> "**") text =
            keep result
        | italicBoundary preceding
        , Just result <-
            enclosed "//" "//" (\inner -> "*" <> go inner <> "*") text =
            keep result
        | Just result <-
            enclosed "__" "__" (\inner -> "<u>" <> go inner <> "</u>") text =
            keep result
        | Just result <- enclosed "''" "''" renderInlineCode text =
            keep result
        | Just result <-
            enclosed "~~" "~~" (\inner -> "~~" <> go inner <> "~~") text =
            keep result
        | Just result <-
            enclosed
                "[["
                "]]"
                (renderZimLink context (convertInline context assets))
                text =
            keep result
        | Just result <- enclosed "{{" "}}" (renderImage assets) text =
            keep result
        | Just result <-
            enclosed "_{" "}" (\inner -> "<sub>" <> go inner <> "</sub>") text =
            keep result
        | Just result <-
            enclosed "^{" "}" (\inner -> "<sup>" <> go inner <> "</sup>") text =
            keep result
        | otherwise = Text.take 1 text <> go (Text.drop 1 text)

    keep (rendered, after) = rendered <> go after

renderAnchor :: Text -> Text
renderAnchor inner =
    let name = Text.strip inner
     in if Text.null name
            then "{{id:}}"
            else
                "<a id=\""
                    <> Text.replace "\"" "&quot;" name
                    <> "\"></a>"

renderImage :: Map.Map Text Text -> Text -> Text
renderImage assets inner =
    let (pathPart, altPart) = Text.breakOn "|" inner
        path = cleanImagePath pathPart
        target = Map.findWithDefault path path assets
        altText =
            if Text.null altPart
                then Text.pack (takeBaseName (Text.unpack path))
                else Text.strip (Text.drop 1 altPart)
     in if Text.null path
            then "{{" <> inner <> "}}"
            else
                "!["
                    <> Text.replace "]" "\\]" altText
                    <> "]("
                    <> renderMarkdownPath target
                    <> ")"

-- | Removes the Zim display options, such as @?width=512@, from an image path.
cleanImagePath :: Text -> Text
cleanImagePath rawPath =
    let trimmed = Text.strip rawPath
     in Text.strip (Text.takeWhile (/= '?') trimmed)

{- | Lists the image paths referenced by a Zim page, without display options.
Anchors such as @{{id: intro}}@ are not images and are ignored.
-}
zimImagePaths :: ZimPage -> [Text]
zimImagePaths (ZimPage content) = go content
  where
    go text =
        case Text.breakOn "{{" text of
            (_, rest)
                | Text.null rest -> []
                | otherwise ->
                    let afterOpening = Text.drop 2 rest
                        (inner, closing) = Text.breakOn "}}" afterOpening
                        remaining = Text.drop 2 closing
                        path = cleanImagePath (Text.takeWhile (/= '|') inner)
                     in if Text.null closing
                            then []
                            else
                                if Text.isPrefixOf "id:" (Text.strip inner) || Text.null path
                                    then go remaining
                                    else path : go remaining
