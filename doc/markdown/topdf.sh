pandoc metadata.yaml Intro.md Vorwort.md IstAnalyse.md Anforderungsanalyse.md Konzept.md Umsetzung.md Anhang.md -H listings-setup.tex -o out.pdf --table-of-contents --listing --filter pandoc-citeproc --number-sections  && open out.pdf