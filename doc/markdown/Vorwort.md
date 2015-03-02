
\newpage

# Vorwort

Sehr geehrte Leserschaft

Smartphones und andere mobilen Geräte haben nicht nur durch ihre Mobilität unseren Alltag und die Arbeitswelt erobert, sondern auch durch neue Bedienkonzepte und durch Bündelung verschiedener Datenquellen und Dienste. Kalender und GPS verbinden Ort und Zeit des Benutzers - das Gerät weiss jederzeit, was der Benutzer gerade tut oder geplant hat und wo er sich befindet und kann daraus Absichten des Benutzers vorhersehen. Konzepte wie Google Now verfolgen diesen Ansatz[^fnGoogleNow]. Das Smartphone wird vermehrt zum intelligenten digitalen Assistenten.

[^fnGoogleNow]: Siehe Quelle [@googleNow]

Mit dieser Vision versuchte ich die firmeninterne Anwendung zur Zeiterfassung ("controllr") für Smartphones neu zu konzipieren. 

Die bestehende Anwendung funktioniert prinzipiell auch auf mobilen Endgeräten mit kleinen Bildschirmen mittels einfachen Verfahren des Responsive Webdesign[^fnResponsiveDesign], doch reicht das reine Umordnen der Elemente in diesem Fall nicht, um den Prozess der Zeiterfassung sinnvoll auf ein Smartphone zu übertragen. Denn nicht nur die Grösse des Bildschirms hat einfluss auf die Bedienbarkeit, sondern auch die Eingabemöglichkeiten des Gerätes. Schaltflächen sind mit einem berührungssensitiven Bildschirms schwerer zu treffen und müssen entsprechend gestaltet werden, ebenso ist die Eingabe von Text auf einem Smartphone aufwendiger und daher langsamer im Vergleich zu einem klassischen Computer mit Maus und Tastatur.

[^fnResponsiveDesign]: Prinzipell werden beim Responsive Webdesign Elemente auf einer Webseite so angeordnet und allenfalls in ihrer Grösse angepasst, sodass sie auf verschiedenen Bildschirmgrössen und -formate sinnvoll Platz haben. Quelle [@responsiveWD]

Um dieses Problem anzugehen überlegte ich mir daher zwei Stossrichtungen: 

- Bedienelemente der Zeiterfassung für Smartphones optimieren 
- Die Menge der Bedienelemente und Eingaben reduzieren

Während die erste Option in der Regel einfacher umzusetzen ist und auch häufig gemacht wird, empfinde ich doch die zweite Variante als weitaus spannender und zeitgemässer. 

Mit der Eingangs erwähnten Vision im Hinterkopf überlegte ich mir daher, wie ich die Anzahl Benutzerinteraktionen für eine Zeiterfassung minimieren kann, indem ich verschiedene Datenquellen eines Mitarbeiters miteinander verbinde. Im Idealfall würde ein Benutzer die Einträge lediglich noch bestätigen müssen.

Die Applikation würde eine Art "Spurensuche" machen, nach den Spuren, die wir bei der täglichen Arbeit hinterlassen. Ausgehend aus dieser Idee entstand auch der Projekt-Name: "TimeTraces".