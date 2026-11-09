-- | Direction-specific conversion entry points.
module ZimToMarkdown.Converter (
    convertMarkdownDocument,
    convertZimPage,
    convertZimPageWithAssets,
    convertZimPageWithAssetsAndFormatting,
) where

import Data.Map.Strict qualified as Map
import Data.Text (Text)

import ZimToMarkdown.Domain (FormattingMode, MarkdownDocument, ZimPage)
import ZimToMarkdown.Links (LinkContext)
import ZimToMarkdown.Markdown (convertMarkdownToZim)
import ZimToMarkdown.Zim (
    convertZimToMarkdown,
    convertZimToMarkdownWithAssets,
    convertZimToMarkdownWithAssetsAndFormatting,
 )

-- | Converts a Zim page into a Markdown document.
convertZimPage :: LinkContext -> ZimPage -> MarkdownDocument
convertZimPage = convertZimToMarkdown

{- | Converts a Zim page into a Markdown document, linking images to the
targets the notebook conversion prepared for them.
-}
convertZimPageWithAssets ::
    LinkContext ->
    Map.Map Text Text ->
    ZimPage ->
    MarkdownDocument
convertZimPageWithAssets = convertZimToMarkdownWithAssets

{- | Converts a Zim page into a Markdown document with prepared image targets
and a formatting mode for inline markup that Markdown cannot express.
-}
convertZimPageWithAssetsAndFormatting ::
    FormattingMode ->
    LinkContext ->
    Map.Map Text Text ->
    ZimPage ->
    MarkdownDocument
convertZimPageWithAssetsAndFormatting =
    convertZimToMarkdownWithAssetsAndFormatting

-- | Converts a Markdown document into a Zim page.
convertMarkdownDocument :: MarkdownDocument -> ZimPage
convertMarkdownDocument = convertMarkdownToZim
