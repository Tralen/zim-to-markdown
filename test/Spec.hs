module Main
    ( main
    ) where

import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as Text
import System.Exit (exitFailure)
import System.FilePath ((</>))

import ZimToMarkdown.Converter (convertMarkdownDocument, convertZimPage)
import ZimToMarkdown.Domain
    ( ConversionDirection (..)
    , MarkdownDocument (..)
    , RelativePath (..)
    , ZimPage (..)
    )
import ZimToMarkdown.Links (LinkContext (..))
import ZimToMarkdown.Notebook (outputRelativePath)

data TestCase = TestCase
    { testName :: String
    , testActual :: Text
    , testExpected :: Text
    }

main :: IO ()
main = do
    let failures =
            [ test
            | test <- tests
            , testExpected test /= testActual test
            ]
    if null failures
        then
            putStrLn
                ("All " <> show (length tests) <> " tests passed.")
        else do
            mapM_ printFailure failures
            exitFailure

printFailure :: TestCase -> IO ()
printFailure test = do
    putStrLn ("FAIL: " <> testName test)
    putStrLn ("  expected: " <> show (testExpected test))
    putStrLn ("  actual:   " <> show (testActual test))

tests :: [TestCase]
tests =
    [ TestCase
        "zim heading level 1"
        (zimToMarkdown "====== Title ======")
        "# Title"
    , TestCase
        "zim heading level 2"
        (zimToMarkdown "===== Second =====")
        "## Second"
    , TestCase
        "zim heading level 5"
        (zimToMarkdown "== Fifth ==")
        "##### Fifth"
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
        "zim root link"
        (zimToMarkdown "[[:root]]")
        "[root](../root.md)"
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
        "{{pic.png}}"
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
zimToMarkdown input =
    unMarkdownDocument (convertZimPage linkContext (ZimPage input))

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
