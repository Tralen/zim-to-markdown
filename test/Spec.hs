module Main (
    main,
) where

import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.IO qualified as TextIO
import Data.Version (showVersion)
import Paths_zim_to_markdown (version)
import System.Directory (doesFileExist)
import System.Exit (exitFailure)
import System.FilePath ((</>))

import ZimToMarkdown.Converter (convertMarkdownDocument, convertZimPage)
import ZimToMarkdown.Domain (
    ConversionDirection (..),
    MarkdownDocument (..),
    RelativePath (..),
    ZimPage (..),
 )
import ZimToMarkdown.Links (LinkContext (..))
import ZimToMarkdown.Notebook (outputRelativePath)
import ZimToMarkdown.Version (versionText)

data TestCase = TestCase
    { testName :: String
    , testActual :: Text
    , testExpected :: Text
    }

main :: IO ()
main = do
    readmeTest <- readmeLinksTest
    let allTests = readmeTest : tests
        failures =
            [ test
            | test <- allTests
            , testExpected test /= testActual test
            ]
    if null failures
        then
            putStrLn
                ("All " <> show (length allTests) <> " tests passed.")
        else do
            mapM_ printFailure failures
            exitFailure

printFailure :: TestCase -> IO ()
printFailure test = do
    putStrLn ("FAIL: " <> testName test)
    putStrLn ("  expected: " <> show (testExpected test))
    putStrLn ("  actual:   " <> show (testActual test))

{- | Checks that every link target in the readme is absolute. Hackage drops
relative links when it renders the package page.
-}
readmeLinksTest :: IO TestCase
readmeLinksTest = do
    present <- doesFileExist readmePath
    content <- if present then TextIO.readFile readmePath else pure ""
    let relativeTargets =
            [ target
            | target <- markdownLinkTargets content
            , not (isAbsoluteLinkTarget target)
            ]
        actual
            | not present = "README.md not found"
            | null relativeTargets = "all link targets are absolute"
            | otherwise =
                Text.intercalate ", " (map Text.strip relativeTargets)
    pure
        TestCase
            { testName = "readme link targets are absolute"
            , testActual = actual
            , testExpected = "all link targets are absolute"
            }
  where
    readmePath = "README.md"

-- | Extracts the destination of every inline Markdown link or image.
markdownLinkTargets :: Text -> [Text]
markdownLinkTargets content =
    case Text.breakOn "](" content of
        (_, remainder)
            | Text.null remainder -> []
            | otherwise ->
                let afterOpening = Text.drop 2 remainder
                    (target, next) = Text.breakOn ")" afterOpening
                 in target : markdownLinkTargets next

isAbsoluteLinkTarget :: Text -> Bool
isAbsoluteLinkTarget rawTarget =
    let target = Text.strip rawTarget
     in any
            (`Text.isPrefixOf` target)
            ["https://", "http://", "mailto:"]
            || Text.isPrefixOf "#" target

tests :: [TestCase]
tests =
    [ TestCase
        "version text matches the Cabal package version"
        versionText
        (Text.pack (showVersion version))
    , TestCase
        "zim heading level 1"
        (zimToMarkdown "====== Title ======")
        "# Title"
    , TestCase
        "zim heading level 2"
        (zimToMarkdown "===== Second =====")
        "# Second"
    , TestCase
        "zim heading level 5"
        (zimToMarkdown "== Fifth ==")
        "# Fifth"
    , TestCase
        "zim heading hierarchy"
        (zimToMarkdown (Text.unlines ["====== Title ======", "", "=== Section ===", "", "== Subsection =="]))
        (Text.unlines ["# Title", "", "## Section", "", "### Subsection"])
    , TestCase
        "zim deep heading hierarchy"
        (zimToMarkdown (Text.unlines ["=== Section ===", "", "== Subsection =="]))
        (Text.unlines ["# Section", "", "## Subsection"])
    , TestCase
        "zim headings are capped at three levels"
        (zimToMarkdown (Text.unlines ["====== Title ======", "===== Two =====", "==== Three ====", "=== Four ===", "== Five =="]))
        (Text.unlines ["# Title", "## Two", "### Three", "### Four", "### Five"])
    , TestCase
        "zim metadata header removed"
        ( zimToMarkdown
            ( Text.unlines
                [ "Content-Type: text/x-zim-wiki"
                , "Wiki-Format: zim 0.6"
                , "Creation-Date: 2016-04-15T16:02:48-03:00"
                , ""
                , "====== Backup ======"
                ]
            )
        )
        (Text.unlines ["# Backup"])
    , TestCase
        "zim bold"
        (zimToMarkdown "**bold**")
        "**bold**"
    , TestCase
        "zim italic"
        (zimToMarkdown "//italic//")
        "*italic*"
    , TestCase
        "zim underline"
        (zimToMarkdown "__under__")
        "<u>under</u>"
    , TestCase
        "zim inline verbatim"
        (zimToMarkdown "''code''")
        "`code`"
    , TestCase
        "zim strikethrough"
        (zimToMarkdown "~~gone~~")
        "~~gone~~"
    , TestCase
        "zim subscript"
        (zimToMarkdown "H_{2}O")
        "H<sub>2</sub>O"
    , TestCase
        "zim superscript"
        (zimToMarkdown "x^{2}")
        "x<sup>2</sup>"
    , TestCase
        "zim bullet list"
        (zimToMarkdown "* item")
        "* item"
    , TestCase
        "zim nested bullet list"
        (zimToMarkdown "\t* sub item")
        "  * sub item"
    , TestCase
        "zim numbered list"
        (zimToMarkdown "1. item")
        "1. item"
    , TestCase
        "zim unchecked task"
        (zimToMarkdown "[ ] todo")
        "- [ ] todo"
    , TestCase
        "zim checked task"
        (zimToMarkdown "[*] done")
        "- [x] done"
    , TestCase
        "zim internal link"
        (zimToMarkdown "[[sibling]]")
        "[sibling](sibling.md)"
    , TestCase
        "zim link label markup"
        (zimToMarkdown "[[sibling|**bold**]]")
        "[**bold**](sibling.md)"
    , TestCase
        "zim root link"
        (zimToMarkdown "[[:root]]")
        "[root](../root.md)"
    , TestCase
        "zim namespace link"
        (zimToMarkdownWithContext rootLinkContext "[[Sistema:cron|página]]")
        "[página](Sistema/cron.md)"
    , TestCase
        "zim pseudo link"
        (zimToMarkdown "[[user@host.example]]")
        "user@host.example"
    , TestCase
        "zim pseudo link with label"
        (zimToMarkdown "[[user@host.example|''user@host.example'']]")
        "user@host.example"
    , TestCase
        "zim child link"
        (zimToMarkdown "[[+child]]")
        "[child](page/child.md)"
    , TestCase
        "zim external link"
        (zimToMarkdown "[[https://example.com|Example]]")
        "[Example](https://example.com)"
    , TestCase
        "zim image"
        (zimToMarkdown "{{./pic.png}}")
        "![pic](./pic.png)"
    , TestCase
        "zim image with alt text"
        (zimToMarkdown "{{./pic.png|A picture}}")
        "![A picture](./pic.png)"
    , TestCase
        "zim anchor"
        (zimToMarkdown "{{id: intro}}")
        "<a id=\"intro\"></a>"
    , TestCase
        "zim html bold"
        (zimToMarkdown "<b>bold</b>")
        "**bold**"
    , TestCase
        "zim html italic"
        (zimToMarkdown "<i>italic</i>")
        "*italic*"
    , TestCase
        "zim migrated task"
        (zimToMarkdown "[>] done")
        "- [x] done"
    , TestCase
        "zim horizontal rule"
        (zimToMarkdown "-----")
        "---"
    , TestCase
        "zim indented block"
        (zimToMarkdown "\tquoted")
        "> quoted"
    , TestCase
        "zim nested indented block"
        (zimToMarkdown "\t\tdeep")
        "> > deep"
    , TestCase
        "zim table with alignment"
        (zimToMarkdown (Text.unlines ["| Name | Age |", "|:-----|----:|", "| Ana | 30 |"]))
        (Text.unlines ["| Name | Age |", "| :--- | ---: |", "| Ana | 30 |"])
    , TestCase
        "zim table without alignment"
        (zimToMarkdown (Text.unlines ["| A | B |", "| 1 | 2 |"]))
        (Text.unlines ["| A | B |", "| --- | --- |", "| 1 | 2 |"])
    , TestCase
        "zim verbatim block"
        (zimToMarkdown (Text.unlines ["'''", "x = 1", "'''"]))
        (Text.unlines ["```", "x = 1", "```"])
    , TestCase
        "markdown heading level 1"
        (markdownToZim "# Title")
        "====== Title ======"
    , TestCase
        "markdown heading level 5"
        (markdownToZim "##### Fifth")
        "== Fifth =="
    , TestCase
        "markdown heading level 6 is clamped"
        (markdownToZim "###### Sixth")
        "== Sixth =="
    , TestCase
        "markdown bold"
        (markdownToZim "**bold**")
        "**bold**"
    , TestCase
        "markdown italic"
        (markdownToZim "*italic*")
        "//italic//"
    , TestCase
        "markdown underscore italic"
        (markdownToZim "_italic_")
        "//italic//"
    , TestCase
        "markdown inline code"
        (markdownToZim "`code`")
        "''code''"
    , TestCase
        "markdown underline html"
        (markdownToZim "<u>under</u>")
        "__under__"
    , TestCase
        "markdown internal link"
        (markdownToZim "[label](page.md)")
        "[[page|label]]"
    , TestCase
        "markdown link label markup"
        (markdownToZim "[**bold**](page.md)")
        "[[page|**bold**]]"
    , TestCase
        "markdown self labelled link"
        (markdownToZim "[page](page.md)")
        "[[page]]"
    , TestCase
        "markdown parent link"
        (markdownToZim "[Home](../Home.md)")
        "[[Home]]"
    , TestCase
        "markdown image"
        (markdownToZim "![alt](pic.png)")
        "{{pic.png|alt}}"
    , TestCase
        "markdown image with alt text"
        (markdownToZim "![A picture](pic.png)")
        "{{pic.png|A picture}}"
    , TestCase
        "markdown anchor"
        (markdownToZim "<a id=\"intro\"></a>")
        "{{id: intro}}"
    , TestCase
        "markdown html strong"
        (markdownToZim "<strong>bold</strong>")
        "**bold**"
    , TestCase
        "markdown html emphasis"
        (markdownToZim "<em>italic</em>")
        "//italic//"
    , TestCase
        "markdown html mark"
        (markdownToZim "<mark>marked</mark>")
        "__marked__"
    , TestCase
        "markdown autolink"
        (markdownToZim "<https://example.com>")
        "[[https://example.com]]"
    , TestCase
        "markdown thematic break"
        (markdownToZim "---")
        "-----"
    , TestCase
        "markdown blank line is not a thematic break"
        (markdownToZim "")
        ""
    , TestCase
        "markdown short marker run is not a thematic break"
        (markdownToZim "--")
        "--"
    , TestCase
        "markdown blockquote"
        (markdownToZim "> quoted")
        "\tquoted"
    , TestCase
        "markdown nested blockquote"
        (markdownToZim "> > deep")
        "\t\tdeep"
    , TestCase
        "markdown list in blockquote"
        (markdownToZim "> - item")
        "\t* item"
    , TestCase
        "markdown setext heading level 1"
        (markdownToZim "Title\n=====")
        "====== Title ======"
    , TestCase
        "markdown setext heading level 2"
        (markdownToZim "Title\n-----")
        "===== Title ====="
    , TestCase
        "markdown table"
        (markdownToZim (Text.unlines ["| Name | Age |", "|:-----|----:|", "| Ana | 30 |"]))
        (Text.unlines ["| Name | Age |", "| :--- | ---: |", "| Ana | 30 |"])
    , TestCase
        "markdown bullet list"
        (markdownToZim "- item")
        "* item"
    , TestCase
        "markdown nested bullet list"
        (markdownToZim "  * nested")
        "\t* nested"
    , TestCase
        "markdown numbered list"
        (markdownToZim "1. item")
        "1. item"
    , TestCase
        "markdown unchecked task"
        (markdownToZim "- [ ] todo")
        "[ ] todo"
    , TestCase
        "markdown checked task"
        (markdownToZim "- [x] done")
        "[*] done"
    , TestCase
        "markdown fenced code"
        (markdownToZim (Text.unlines ["```", "x = 1", "```"]))
        (Text.unlines ["'''", "x = 1", "'''"])
    , TestCase
        "notebook zim output path"
        (Text.pack (unRelativePath (outputRelativePath ZimToMarkdown (RelativePath ("notes" </> "page.txt")))))
        (Text.pack ("notes" </> "page.md"))
    , TestCase
        "notebook markdown output path"
        (Text.pack (unRelativePath (outputRelativePath MarkdownToZim (RelativePath ("notes" </> "page.md")))))
        (Text.pack ("notes" </> "page.txt"))
    ]

zimToMarkdown :: Text -> Text
zimToMarkdown = zimToMarkdownWithContext linkContext

zimToMarkdownWithContext :: LinkContext -> Text -> Text
zimToMarkdownWithContext context input =
    unMarkdownDocument (convertZimPage context (ZimPage input))

markdownToZim :: Text -> Text
markdownToZim input =
    unZimPage (convertMarkdownDocument (MarkdownDocument input))

linkContext :: LinkContext
linkContext =
    LinkContext
        { linkCurrentPage = RelativePath ("notes" </> "page.txt")
        , linkKnownPages =
            Set.fromList
                [ RelativePath ("notes" </> "page.txt")
                , RelativePath ("notes" </> "sibling.txt")
                , RelativePath "root.txt"
                , RelativePath ("notes" </> "page" </> "child.txt")
                ]
        }

rootLinkContext :: LinkContext
rootLinkContext =
    LinkContext
        { linkCurrentPage = RelativePath "Backup.txt"
        , linkKnownPages =
            Set.fromList
                [ RelativePath "Backup.txt"
                , RelativePath ("Sistema" </> "cron.txt")
                ]
        }
