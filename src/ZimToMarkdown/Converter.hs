-- | Direction-specific conversion entry points.
module ZimToMarkdown.Converter (
    convertMarkdownDocument,
    convertZimPage,
    convertZimPageWithAssets,
) where

import Data.Map.Strict qualified as Map
import Data.Text (Text)

import ZimToMarkdown.Domain (MarkdownDocument, RelativePath, ZimPage)
import ZimToMarkdown.Links (LinkContext)
import ZimToMarkdown.Markdown (convertMarkdownToZim)
import ZimToMarkdown.Zim (convertZimToMarkdown, convertZimToMarkdownWithAssets)

-- | Converts a Zim page into a Markdown document.
convertZimPage :: LinkContext -> ZimPage -> MarkdownDocument
convertZimPage = convertZimToMarkdown

{- | Converts a Zim page into a Markdown document, linking images to the
assets the notebook conversion copied for them.
-}
convertZimPageWithAssets ::
    LinkContext ->
    Map.Map Text RelativePath ->
    ZimPage ->
    MarkdownDocument
convertZimPageWithAssets = convertZimToMarkdownWithAssets

-- | Converts a Markdown document into a Zim page.
convertMarkdownDocument :: MarkdownDocument -> ZimPage
convertMarkdownDocument = convertMarkdownToZim
