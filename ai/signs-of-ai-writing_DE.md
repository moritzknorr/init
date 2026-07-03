# Leitfaden: Erkennung von KI-generierten Inhalten (Deutschen Wikipedia)

Dieser Leitfaden fasst die typischen sprachlichen, strukturellen und technischen Muster zusammen, die auf unzulässig generierte Texte durch Chatbots (wie ChatGPT, Gemini, Claude) hinweisen.

---

## 1. Eindeutige Indikatoren (Harte Beweise)
* **Falsche Belege (Halluzinationen):** Zitierte Quellen, URLs, ISBN-Nummern oder DOIs existieren nicht, oder der Inhalt des realen Belegs stimmt absolut nicht mit der Behauptung im Text überein.
* **Formulierungsreste & Chatbot-Dialoge:** Direkte Übernahme von Floskeln aus dem Bot-Interface (z. B. *"Ich hoffe, das hilft"*, *"Natürlich!"*, *"Sicherlich!"*).
* **Briefartiges Schreiben:** Unübliche Höflichkeitsformeln oder E-Mail-Strukturen auf Diskussionsseiten (z. B. *"Liebe Wikipedia-Editoren"*, Vorhandensein einer Betreffzeile).
* **Hinweise auf Wissenslücken:** Sätze wie *"Stand meines letzten Wissensupdates [Datum]"* oder *"Obwohl spezifische Details begrenzt sind, unterstützt der Berg wahrscheinlich..."* (reine Spekulation bei fehlenden RAG-Ergebnissen).
* **Vergessene Platzhalter:** Unausgefüllte Lückentext-Vorlagen der KI (z. B. *[Fügen Sie hier das Geburtsdatum ein]*).
* **Nicht existierende Vorlagen:** KI-erfundene Wikipedia-Vorlagen oder Parameter, die rote Links erzeugen.

## 2. Weichere sprachliche Anzeichen (Stil & Tonfall)
* **Werbe- und Reiseführersprache ("Puffery"):** Fehlender neutraler Tonfall durch Phrasen wie *reiches kulturelles Erbe, atemberaubend, eingebettet im Herzen von, spielt eine entscheidende Rolle, Wendepunkt, unerschütterliche Hingabe.*
* **Redaktionelle Kommentare:** Für die Wikipedia unpassende Einschübe wie *"Es ist wichtig zu beachten..."* oder *"Keine Diskussion wäre vollständig ohne..."*.
* **Mechanische Konjunktionen:** Inflationäre und steife Verwendung von Bindewörtern (*darüber hinaus, zusätzlich, außerdem, ferner*).
* **Abschnitts-Zusammenfassungen & Fazits:** Textblöcke oder Artikel, die fälschlicherweise mit Zusammenfassungen (*"zusammenfassend"*, *"abschließend"*) oder einem eigenständigen Abschnitt *"Fazit"* enden.
* **Geschwätzige Partizip-I-Konstruktionen:** Künstlich wirkende Satzenden (z. B. *"...gewährleistend"*, *"...hervorhebend"*, *"...widerspiegelnd"*), die oft eine direkte Übersetzung englischer *-ing*-Formen sind.
* **Argumentative Dreierregeln (Trikolon):** Mechanische Aufzählungen von drei Adjektiven oder kurzen Phrasen, um Oberflächlichkeit zu kaschieren.

## 3. Formatierungs- & Markup-Fehler
* **Markdown-Syntax statt Wikitext:** Verwendung von Rautezeichen für Überschriften (`## Geographie`), doppelten Sternchen für Fettschrift (`**Text**`) oder drei Bindestrichen (`---`) für Trennlinien.
* **Überstrukturiere Listen:** Artikel, die fast nur aus Listen bestehen, wobei Aufzählungspunkte als echte Bullets (•), Bindestriche (-) oder Nummerierungen aus der Zwischenablage kopiert wurden.
* **Emojis:** Unübliche Emojis vor Abschnittsüberschriften oder Listenpunkten.
* **Fehlerhafter Wikitext:** Auftreten von Code-Resten wie *"Gehe zu Suche Nr."* (entsteht beim Kopieren von KI-Texten mit externen Verlinkungen seit Februar 2025).

## 4. Benutzerbezogene Kriterien
* **Abrupter Schreibstilwechsel:** Plötzlich fehlerfreie Grammatik und hochformales Register bei Nutzern, die zuvor eher umgangssprachlich oder fehlerhaft geschrieben haben.
* **Produktivitätsschub:** Massenhaftes Erstellen oder Umschreiben von Artikeln in kürzester Zeit (Verdacht auf "Permissions Gaming").
* **KI-generierte Bearbeitungszusammenfassungen:** Ungewöhnlich lange, in der ersten Person verfasste Zusammenfassungen in der Versionsgeschichte, die ohne Abkürzungen Wikipedia-Richtlinien herunterbeten.
* **UTM-Parameter:** Protokollierung des Filters 453 bei URLs mit dem Parameter `?utm_source=chatgpt.com`.
