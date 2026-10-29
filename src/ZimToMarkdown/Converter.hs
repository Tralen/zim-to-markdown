-- | Direction-specific conversion entry points.
module ZimToMarkdown.Converter (
    convertMarkdownDocument,
    convertZimPage,
    convertZimPageWithAssets,
) where

import Data.Map.Strict qualified as Map
import Data.Text (Text)

import ZimToMarkdown.Domain (MarkdownDocument, ZimPage)
import ZimToMarkdown.Links (LinkContext)
import ZimToMarkdown.Markdown (convertMarkdownToZim)
import ZimToMarkdown.Zim (convertZimToMarkdown, convertZimToMarkdownWithAssets)

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

-- | Converts a Markdown document into a Zim page.
convertMarkdownDocument :: MarkdownDocument -> ZimPage
convertMarkdownDocument = convertMarkdownToZim
