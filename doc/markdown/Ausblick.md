
\pagebreak

# Ausblick und Diskussion

Die Arbeit war sowohl aus konzeptioneller, wie auch aus technischer Sicht herausfordernd, zeigt aber auch eine spannende Richtung, wie Dienste verbunden werden können um Prozesse zu automatisieren. 

Der umgesetzte Prototyp stiess auf Anklang, es kamen auch bereits weitere Ideen und Verbesserungen auf, die in einem neuen Rahmen zukünftig umgesetzt werden sollen. Auch die Architektur erwiess sich als sinnvoll, neue Datenquellen können zukünftig mit wenig Aufwand eingebunden werden. 


## Vorteile von "Reactive REST-Mapping"

Das Verfahren des "Reactive REST-Mapping" wurde über die ganze Anwendung hinweg gebraucht und erleichterte den Umgang mit den REST-Schnittstellen sehr. So werden Projekte aus Redmine, "Issues" aus Redmine, "Events" aus Github, sowie "Events" aus dem Google Kalender und "TimeEntries" aus "Controllr" periodisch geladen und alle Ansichten, welche diese Daten nutzen automatisch aktualisiert. 

Ein weiterer Vorteil dieses Verfahren ist, dass die Datenquelle für den Client völlig transparent ist, der Client "sieht" nur gewöhnliche Meteor-Collections. So lässt sich die Datenquelle oder die Anbindungs-Technologie einfach austauschen um beispielsweise von einem "Polling"[^fnPolling] auf ein Nachrichten-basiertes System zu wechseln, wie es bereits zwischen Client und Server existiert. Damit entfällt die Verzögerung, die durch das Polling-Interval entsteht.

Durch diesen Zwischenschritt über den serverseitigen Teil der Applikation kommuniziert ein Client auch nie direkt mit einer Datenquelle. Dies kann sicherheitstechnische Vorteile haben und ermöglicht auch, häufig abgefragte Daten auf dem Server zwischenzuspeichern (siehe dazu nächster Abschnitt).

[^fnPolling]: Die Datenquelle wird periodisch abgefragt.

## Probleme und Erweiterungen zum "Reactive REST-Mapping"

Meteor verwaltet für jeden aktiven Benutzer eine Verbindung und zugehörige Abonnements ("subscriptions"). Dieses Konzept wurde bei der Gestaltung von `panter:publish-array` berücksichtigt; jeder aktive Benutzer erhält eine eigene aktive "subscription", welche auf dem Server die abonnierten Quellen regelmässig nach neuen Daten abfragt. Nachteil an dieser Lösung ist, dass bei mehreren aktiven Benutzern die Quellen sehr häufig kontaktiert werden, auch wenn die abgefragten Daten teilweise identisch sind. So ist die Projekt- und Task-Liste von "controllr" für alle Benutzer identisch. Eine Lösung wäre, diese Daten im serverseitigen Teil der Applikation zwischenzuspeichern und unter den abonnierenden Benutzer zu teilen. Diese Erweiterung könnte innerhalb von `panter:publish-array`gemacht werden.


## Schwierigkeiten bei der Darstellung

Schwierigkeiten traten bei der visuellen Gestaltung auf: zwar lag der Fokus darauf, Benutzerinteraktionen zu minimieren und nicht auf der visuellen Darstellung, dennoch sind minimale Überlegungen dazu nötig. 

Wie in Abbildung \ref{figEventsApp} zu sehen, können nicht immer alle Infos für ein Event angezeigt werden, wenn das Ereignis kurz ist. Eine Herausforderung war, den Skalierungsfaktor so zu wählen, das kleine Events noch sinnvoll angetippt werden können und noch die nötigsten Informationen zeigen. Ein zu grosser Skalierungsfaktor würde hingegen die Liste zu stark in der Höhe vergrössern, was die Übersicht reduziert.

Auch wurde die obige Abbildung auf einem relativ grossen Bildschirm gemacht. Auf kleinen Smartphone-Bildschirmen ist die Übersicht noch etwas eingeschränkter.

Mögliche Lösungen sind:

- Infos reduzieren (z.b. Beschreibungstext entfernen)
- Nutzung von Symbolen, z.b. für Task-Typen
- Skalierung dynamisch, z.b. minimale Höhe für kürzestes Event eines Tages

Abbildung \ref{figForm} zeigt zudem, dass die grundsätzlichen Eingabe-Felder der Ursprünglichen Applikation nicht direkt reduziert wurden, sie werden lediglich vor-ausgefüllt. Ein weitergehender Ansatz wäre, diese Felder auch tatsächlich auszublenden oder nur optional einzublenden, wenn der User etwas anpassen möchte. Zudem könnten die Felder, sofern der Benutzer doch ein Feld anpassen möchte, noch weiter für mobile Endgeräte zu optimieren.

Es ist dennoch möglich, dass der Benutzer lediglich den Zeiteintrag bestätigen muss, sofern alle Felder für ihn bereits stimmen. Dies kommt der Eingangs erwähnten Idealvorstellung bereits nahe.


