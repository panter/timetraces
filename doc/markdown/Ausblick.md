
\pagebreak

# Ausblick und Diskussion

Die Arbeit war sowohl aus konzeptioneller, wie auch aus technischer Sicht herausfordernd, zeigt aber auch eine spannende Richtung, wie Dienste verbunden werden können um Prozesse zu automatisieren. 

Der umgesetzte Prototyp stiess auf Anklang, es kamen auch bereits weitere Ideen und Verbesserungen auf, die in einem neuen Rahmen zukünftig umgesetzt werden sollen. Auch die Architektur erwiess sich als sinnvoll, neue Datenquellen können zukünftig mit wenig Aufwand eingebunden werden. 

Schwierigkeiten traten bei der visuellen Gestaltung auf: zwar lag der Fokus darauf, Benutzerinteraktionen zu minimieren und nicht auf der visuellen Darstellung, dennoch sind minimale Überlegungen dazu nötig. 

Wie in Abbildung \ref{figEventsApp} zu sehen, können nicht immer alle Infos für ein Event angezeigt werden, wenn das Ereignis kurz ist. Eine Herausforderung war, den Skalierungsfaktor so zu wählen, das kleine Events noch sinnvoll angetippt werden können und noch die nötigsten Informationen zeigen. Ein zu grosser Skalierungsfaktor würde hingegen die Liste zu stark in der Höhe vergrössern, was die Übersicht reduziert.

Auch wurde die obige Abbildung auf einem relativ grossen Bildschirm gemacht. Auf kleinen Smartphone-Bildschirmen ist die Übersicht noch etwas eingeschränkter.

Mögliche Lösungen sind:

- Infos reduzieren (z.b. Beschreibungstext entfernen)
- Nutzung von Symbolen, z.b. für Task-Typen
- Skalierung dynamisch, z.b. minimale Höhe für kürzestes Event eines Tages

Abbildung \ref{figForm} zeigt zudem, dass die grundsätzlichen Eingabe-Felder der Ursprünglichen Applikation nicht direkt reduziert wurden, sie werden lediglich vor-ausgefüllt. Ein weitergehender Ansatz wäre, diese Felder auch tatsächlich auszublenden oder nur optional einzublenden, wenn der User etwas anpassen möchte. 

Es ist dennoch möglich, dass der Benutzer lediglich den Zeiteintrag bestätigen muss, sofern alle Felder für ihn bereits stimmen. Dies kommt der Eingangs erwähnten Idealvorstellung bereits nahe.



