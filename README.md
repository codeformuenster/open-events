Open Events Database
====================

Hier die Eckpunkte, (copy and paste aus dem Forum.. http://forum.codeformuenster.org/t/open-calendar-offene-termindatenbank/109 )

Geplante Features / ToDo
* JSON API zum Einsenden von Terminen
* JSON API zum Abholen von Terminen
* Oauth Anmeldung für die JSON API
* Termin-Eingabe-Formular prominent deployen :-)
* "Termin-Suche": Beispiel-Webanwendung zum Termine suchen


**Datastore**
* Wir stellen erstmal hauptsächlich den Datenspeicher an sich zur Verfügung. Dort werden alle Events im JSON-Format gespeichert mit: 
 * Termin-Titel
 * Datum
 * Kategorie(n)
 * Lat/Long
 * Beschreibung
* Weitere Felder?
* ElasticSearch bietet sich dafür an
* Abgelegt werden die Daten im JSON Format, am besten wäre ein offener Standard wie z.B. das Events Format von schema.org: http://schema.org/Event auch JSON-LD sollte man sich angucken: http://json-ld.org/playground/index.html

**Input-Services** "Wie kommen die Termine rein?"
* Um Events in den Data-Store zu pushen, kann jeder interessierte Bürger Microservices schreiben
* @tomsrocket hat ein paar Scraper geschrieben, die Events von diversen Locations aus dem Münster Stadtgebiet abrufen, und wird diese in die Termindatenbank schreiben
* @webwurst hatte die Idee, mit dem JSON Schema based Editor ein Eingabeformular zu erstellen: https://github.com/jdorn/json-editor
* Zum Formular könnte man einen OAuth Login hinzufügen, quasi als Termin-Ownership, so dass man die selbst eingetragenen Termine später wieder bearbeiten kann.
* Somit hätten wir durch die Scraper einen Grundstock an Terminen, und zusätzlich können die Leute Termine eintragen über das Formular

**Output-Services** "Warum das Ganze?"
* Man könnte Email-Services programmieren, wie z.B. "Schick mir wöchentlich eine Email mit allen anstehenden Rockkonzerten", oder "1x im Monat eine Liste der Flohmärkte". Theoretisch können sich die Leute sowas mit IFTT auch selbst bauen. => Damit schaffen wir einen direkten Mehrwert, der ggf. dabei Hilft, die Termindatenbank bekannt zu machen und einen Anreiz schafft, dort Termine einzutragen.
* Man könnte eine schicke Webseite mit einer Abfrage-Schnittstelle & Terminliste schaffen.
* ICAL- oder Google Calender kompatible Dateien ausspucken 
* etc... 
* Technische Umsetzung: Wir wollen offenen Zugriff auf das ElasticSearch Datastore zulassen. Bzw., das ElasticSearch API direkt exposen, das ist evtl. nicht so eine gute Idee, da man damit auch die ganze Datenbank kaputtmachen kann. Insofern müsste man die API durch einen Proxy filtern und nur bestimmte Abfragen zulassen. Im Endeffekt so a la 4square, google calendar oder facebook API.

