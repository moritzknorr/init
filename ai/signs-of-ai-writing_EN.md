# Field Guide: Detecting AI-Generated Content on Wikipedia

This guide outlines the major technical, stylistic, and structural "tells" left behind by Large Language Models (LLMs) like ChatGPT, Claude, Gemini, and Grok.

---

## 1. Stylistic & Vocabulary "Tells"
* **AI Vocabulary Eras:** * *2023–Mid 2024:* Heavy use of *delve, tapestry, testament, meticulously, intricate, interplay, pivotal, underscore.*
  * *Mid 2024–Mid 2025:* Shift to *align with, fostering, showcasing, vibrant, enhance.*
  * *Mid 2025 onward:* Dominance of *highlighting, showcasing*, and media-notability buzzwords.
* **Copula Avoidance:** LLMs systematically avoid simple "is" or "are" constructions, replacing them with *serves as, stands as, boasts, features, holds the distinction of.*
* **Negative Parallelisms:** Frequent use of argumentative structures like *"Not only... but also"*, *"Not X, but Y"*, or *"X rather than Y"*.
* **Rule of Three:** Overuse of triadic patterns (e.g., *"adjective, adjective, and adjective"* or three short consecutive clauses) to make superficial analysis sound comprehensive.

## 2. Content & Structural Tells
* **Regression to the Mean:** Replacing specific, unique historical facts with generic, exaggerated fluff (e.g., changing *"inventor of the first train-coupling device"* to *"a revolutionary titan of industry"*).
* **Canned Notability Claims:** Hitting the reader over the head with phrases like *independent coverage, trade publications, profiled in*, or *maintains an active social media presence*.
* **Ecosystem/Conservation Bloat:** In biology articles, LLMs obsessively write about generic ecosystem connections and preservation efforts, even if the species' status is completely unknown.
* **Rigid Outline Conclusions:** Articles ending in a "Challenges and Future Prospects" section that formulaically begins with *"Despite its [success], [subject] faces challenges..."*

## 3. Formatting & Markup Footprints
* **Markdown Instead of Wikitext:** Using hashes (`## Heading`) instead of equals signs, asterisks (`**bold**`) instead of single quotes, or triple hyphens (`---`) for thematic breaks.
* **Inline-Header Vertical Lists:** Bulleted lists where each bullet starts with a mechanically bolded title followed by a colon (e.g., * **Topic:** Description*).
* **Typographic Quirks:** Overusing spaced em dashes ( ` — ` ) to punch up sales-like writing, or defaulting to curly quotation marks (`""`) and apostrophes (`'`).

## 4. Technical Artifacts & System Leaks
* **UTM Tracers:** URLs containing tracking parameters like `?utm_source=chatgpt.com`, `?utm_source=openai`, `?utm_source=copilot.com`, or `referrer=grok.com`.
* **RAG / Search Placeholder Bugs:** * ChatGPT: Texts containing `cite turn0search0`, `:contentReference[oaicite:0]`, or `oai_citation`.
  * DeepSeek: Content containing lenticular brackets and daggers like `【85 L261-269】`.
  * [cite_start]Gemini: Stray `[cite: 1]` style markers.
  * Perplexity / Grok: Tags like `[attached_file:1]` or `<grok-card>`.
* **Fill-in-the-Blank Blanks:** Users forgetting to clean up templates, leaving texts like `[Your Name]` or `[Describe the specific section]`.
* **Hallucinated References:** Fabricated DOIs, invalid ISBN checksums, non-existent Wikipedia templates, or book citations missing page numbers.

## 5. Behavioral Tell-Tales
* **Chatbot Correspondence Leaks:** Pasting the AI's conversational filler text directly into articles (e.g., *"I hope this helps!"*, *"Certainly! Here is a draft..."*).
* **Overwhelming Edit Summaries:** Writing verbose, first-person paragraphs in the edit history itemizing compliance with "WP:NPOV" instead of a short summary.
