
\newpage

# Konzept

## Begriffe

Event
: 	Als “Event” wird in der Arbeit ein Ereignis mit einem bestimmten Zeitpunkt, sowie Beschreibung und anderen Daten angesehen. Die “Events” der zu verwendenen Quellen, haben in der Regel keine Zeitdauer und damit keine Start- und Endzeit, mit Ausnahme der Daten aus dem Kalender.
	Ein Event kann im einfachen Fall ein Kalendereintrag sein. Es kann aber auch ein Commit auf Github sein, ein abgeschlossener Task auf Redmine oder ähnliches. Ein Event kann man damit auch als “Spur” (engl. “Trace”) verstehen, die die tägliche Arbeit hinterlässt.

Timeentry
:	Unter “Timeentry”[^fnTimeEntry] wird ein zu erstellender Zeiteintrag auf der Zeiterfassungsapplikation (Controllr) verstanden. Im Gegensatz zu einem “Event”, verfügt ein “Timeentry” immer über eine Start- und eine Endzeit. Zudem wird einem “Timeentry” einem Projekt, einem Task und einem Datum zugewiesen und mit Beschreibung und weiteren Metadaten versehen.
	Ein “Timeentry” entspricht also dem Modell eines geleisteten Stücks Arbeit, welches es zu protokollieren gilt.

[^fnTimeEntry]:	Einfache transkription aus dem Englischen von “Zeiteintrag” in Anlehnung an “Entry”, dem Datenmodel, welches in der Zeiterfassungsapplikation “Controllr” verwendet wird

## Vom Event zum Timeentry\label{secEventTimeEntry}

Listet man alle gesammelten “Events” eines Tages nacheinander auf, erhält man ein erstes Protokoll. Um daraus konkrete Zeiteinträge zu erstellen, müssen die Events noch umgeformt und mit weiteren Daten versehen werden:

### Projekt und Task-zuweisung

Jedem Timeentry auf dem Controllr muss ein Projekt und ein Task zugewiesen werden. Die Liste der Projekte und Tasks können von einer Schnittstelle abgerufen werden. Jedes Projekt und jeder Task verfügt über einen Namen und eine Beschreibung. Um für ein Event ein Task und ein Projekt zu bestimmen, ergeben sich folgende Möglichkeiten:

- Der Beschreibungstext und andere Metadaten des Events werden nach Projektnamen durchsucht und das entsprechende Projekt bei einem Treffer dem Event zugewiesen
- Github-Events entsprechen i.d.R. einem “Development”-Task
- Kalendereinträge entsprechen einem “Meeting”-Task
- Der Enduser kann selbst Regeln bestimmen, beispielsweise indem er Schlüsselwörter definiert, welche ein bestimmtes Projekt oder einen bestimmten Task forcieren.

### Fehlende Start- und Endzeit

Die Events aus den meisten Quellen besitzen aber nur einen Zeitpunkt, keinen Start- und Endzeitpunkt. Es müssen also gewisse Annahmen getroffen werden, um Start- und Endpunkt zu bestimmen. Folgende Annahmen ergeben sich:

- Der Zeitpunkt jedes Events entspricht dem Zeitpunkt, an dem eine Arbeit **beendet wurde**. 
	- In Hinblick auf Github-Commits trifft dies zu, da man i.d.R. nach einer Programmieraufgabe diese Änderungen in die Versionskontrolle speichert. 
	- Bei Redmine wird man häufig nach getaner Arbeit einen Task als Erledigt markieren oder den Progress des Tasks ändern
- Nach einem abgeschlossenen Task wendet man sich dem nächsten Task zu. Die **Startzeit eines Events** entspricht daher der **Endzeit des letzten Events**
- Die **Startzeit des ersten Events an einem Tag** ist der übliche Arbeitsbeginn eines Mitarbeiters.

#### Probleme:

Kalendereinträge verfügen immer über eine Startzeit, wenn es sich nicht um Tagesevents handelt. Sie können sich daher mit Einzel-Events aus anderen Quellen überlappen. Ebenfalls ist es möglich in Kalendern überlappende Einträge zu erstellen.

Mehrere Events können sehr nahe aneinander liegen. Ein mögliches Szenario wäre, wenn ein Benutzer einen Github-Commit erstellt und danach den entsprechenden Task in Redmine aktualisiert. In diesem Falle würden beide Events sogar die gleiche Arbeit protokollieren.

Um diese Probleme zu umgehen, können mehrere Events miteinander kombiniert (“Merging”) werden.

### “Merging” - Kombinieren von Events

Nah aneinanderliegende Events oder überlappende Events können miteinander kombiniert werden und als ein Event gezählt werden. Dies vereinfacht die Handhabung und die Darstellung von Events. Events dürfen aber nur kombiniert werden, wenn sie auch zum gleichen Projekt gehören. Es ergeben sich daher folgende mögliche Regeln:

- Zwei Events können kombiniert werden, wenn sie mutasslich zum gleichen Projekt gehören.
- Das Ende des zweiten Events (d.h. mit späterer End-Zeit) liegt nahe am Ende des ersten Events (Es ist ein Grenzwert zu definieren)
- Die Gesamtlänge der kombinierten Events sollte einen weiteren Grenzwert nicht überschreiten
- Die Startzeit des zweiten Events liegt vor der Endzeit des ersten Events (Überlappung)


## Mögliche Darstellungen

### Kalender-Darstellung

Abbildung \ref{figCalendar} zeigt eine übliche Darstellung einer Kalender-Applikationen. Dabei wird jeder Tag als Spalte dargestellt mit dem Begin des Tages oben und das Ende unten.

![Beispiel Kalender Applikation\label{figCalendar}[@businessCalendar]](../img/calendar.jpg)


Diese Darstellung eignet sich auch für die geplante Zeiterfassungsanwendung. "Events" eines Tages können wie die Ereignisse in einem normalen Kalender dargestellt werden.

**Vorteile:**

- Sie zeigt die relativen Unterschiede der Zeiten durch proportional unterschiedliche Höhen der einzelnen Blöcke
- Sie kann je nach Spaltenbreite mehrere Tage gleichzeitig darstellen
- Sie ermöglicht dem Betrachter qualitativ festzustellen, wieviel Aktivität an einem Tag stattfand

**Nachteile:**

- Kurze Events können sehr klein werden - und dadurch auch schwer klickbar
- Je nach Breite ist nur sehr wenig Platz vorhanden für Beschriftungen oder Details auf den einzelnen Einträgen, bei kurzen Events ist dies noch akuter.
- Die Umsetzung einer solchen Darstellung ist vergleichsweise aufwendig

### Listen-Darstellung

Viele Kalender bieten als alternative Darstellung eine Listenansicht an. In dieser Ansicht werden Einträge untereinander aufgelistet ohne dass die Zeitdauer berücksichtigt wird. 

**Vorteile:**

- Jeder Eintrag kann gleich gross dargestellt werden und somit steht für Titel oder Beschreibung des Eintrages genug Platz zur Verfügung.
- Die Ansicht kann sehr kompakt gemacht werden, insbesondere, wenn an einem Tag nur wenige Ereignisse eingetragen sind
- Einfach zu implementieren

**Nachteile:**

- Für den Betrachter ist nicht direkt ersichtlich, wie lange ein einzelnes Ereignis dauert


## Datenquellen für den Prototyp

Für den Prototyp wurde folgende Systeme zur Anbindung gewählt:

Google Kalender, Redmine (Issues), Github (Events). Obwohl nach der Umfrage Emails ebenfalls sehr häufig genutzt werden, wurde auf die Abfrage von Emails verzichtet, da diese schwieriger auszuwerten sind.









