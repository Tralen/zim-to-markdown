module ZimToMarkdown.Converter
    ( convertMarkdownDocument
    , convertZimPage
    ) where

import ZimToMarkdown.Domain (MarkdownDocument, ZimPage)
import ZimToMarkdown.Links (LinkContext)
import ZimToMarkdown.Markdown (convertMarkdownToZim)
import ZimToMarkdown.Zim (convertZimToMarkdown)

-- | Converts a Zim page into a Markdown document.
convertZimPage :: LinkContext -> ZimPage -> MarkdownDocument
convertZimPage = convertZimToMarkdown

-- | Converts a Markdown document into a Zim page.
convertMarkdownDocument :: MarkdownDocument -> ZimPage
convertMarkdownDocument = convertMarkdownToZim
