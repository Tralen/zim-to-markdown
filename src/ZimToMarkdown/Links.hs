module ZimToMarkdown.Links
    ( LinkContext (..)
    , isExternalTarget
    , renderZimLink
    ) where

import Data.Char (toLower)
import Data.List (find)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as Text
import System.FilePath
    ( addExtension
    , dropExtension
    , normalise
    , takeDirectory
    , takeExtension
    , (</>)
    )

import ZimToMarkdown.Domain (RelativePath (..))
import ZimToMarkdown.Inline (renderMarkdownPath)
import ZimToMarkdown.Paths (relativePathFrom, toPosixPath)

-- | The notebook context needed to resolve internal Zim links.
data LinkContext = LinkContext
    { linkCurrentPage :: RelativePath
    , linkKnownPages :: Set.Set RelativePath
    }
    deriving (Eq, Show)

-- | Converts the inner text of a Zim link into a Markdown link. The label
-- renderer converts inline markup inside an explicit link label.
renderZimLink :: LinkContext -> (Text -> Text) -> Text -> Text
renderZimLink context renderLabel rawInner =
    let inner = Text.strip rawInner
    in if Text.null inner
        then ""
        else
            let (target, label) = splitLink inner
            in if Text.null target
                then escapeLabel (maybe "" renderLabel label)
                else
                    if isExternalTarget target
                        then renderExternal renderLabel target label
                        else renderInternal context renderLabel target label

-- | Tests whether a link target points outside the notebook.
isExternalTarget :: Text -> Bool
isExternalTarget target =
    any
        (`Text.isPrefixOf` target)
        ["http://", "https://", "ftp://", "ftps://", "mailto:", "file:"]
        || "://" `Text.isInfixOf` target

splitLink :: Text -> (Text, Maybe Text)
splitLink inner =
    let (target, labelWithPipe) = Text.breakOn "|" inner
    in ( Text.strip target
       , if Text.null labelWithPipe
            then Nothing
            else Just (Text.strip (Text.drop 1 labelWithPipe))
       )

renderExternal :: (Text -> Text) -> Text -> Maybe Text -> Text
renderExternal renderLabel target label =
    "["
        <> escapeLabel (maybe target renderLabel label)
        <> "]("
        <> renderMarkdownPath target
        <> ")"

renderInternal :: LinkContext -> (Text -> Text) -> Text -> Maybe Text -> Text
renderInternal context renderLabel target label =
    let (pathPart, anchor) = Text.breakOn "#" target
        cleanTarget = Text.strip pathPart
        display =
            case label of
                Just value -> renderLabel value
                Nothing -> stripLinkPrefix target
    in if Text.null cleanTarget
        then escapeLabel display
        else
            let resolved = resolveTarget context (Text.unpack cleanTarget)
                withAnchor = resolved <> Text.unpack anchor
            in "["
                <> escapeLabel display
                <> "]("
                <> renderMarkdownPath (Text.pack withAnchor)
                <> ")"

stripLinkPrefix :: Text -> Text
stripLinkPrefix text =
    let cleaned =
            Text.dropWhile
                (\character -> character == ':' || character == '+')
                (Text.strip text)
    in if Text.null cleaned then Text.strip text else cleaned

escapeLabel :: Text -> Text
escapeLabel = Text.replace "]" "\\]"

resolveTarget :: LinkContext -> FilePath -> FilePath
resolveTarget context rawTarget =
    let currentPage = unRelativePath (linkCurrentPage context)
        currentDirectory = takeDirectory currentPage
        target = stripSourceExtension (normalise rawTarget)
        (candidates, fallback) =
            targetCandidates currentPage currentDirectory target
        chosen =
            case find (isKnownPage context) candidates of
                Just candidate -> candidate
                Nothing -> fallback
        markdownPath = addExtension chosen "md"
        relativePath =
            normalise
                (relativePathFrom currentDirectory markdownPath)
    in toPosixPath relativePath

targetCandidates :: FilePath -> FilePath -> FilePath -> ([FilePath], FilePath)
targetCandidates currentPage currentDirectory target =
    case target of
        ':' : rest ->
            let rooted = normalise (dropLeadingSeparators rest)
            in ([rooted], rooted)
        '+' : rest ->
            let child = normalise (dropExtension currentPage </> rest)
            in ([child], child)
        _ ->
            let parents = parentDirectories currentDirectory
                candidates =
                    [normalise (directory </> target) | directory <- parents]
                        <> [normalise target]
                fallback =
                    if currentDirectory == "."
                        then normalise target
                        else normalise (currentDirectory </> target)
            in (candidates, fallback)

parentDirectories :: FilePath -> [FilePath]
parentDirectories directory
    | directory == "."
        || directory == "/"
        || null directory =
        []
    | otherwise = directory : parentDirectories (takeDirectory directory)

dropLeadingSeparators :: FilePath -> FilePath
dropLeadingSeparators = dropWhile (== '/')

stripSourceExtension :: FilePath -> FilePath
stripSourceExtension path =
    if map toLower (takeExtension path) == ".txt"
        then dropExtension path
        else path

isKnownPage :: LinkContext -> FilePath -> Bool
isKnownPage context candidate =
    Set.member
        (RelativePath (normalise (addExtension candidate "txt")))
        (linkKnownPages context)
