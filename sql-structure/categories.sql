

drop table category2event;
drop table category;



create table category (
 `category_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  category_name varchar(255) NOT NULL,
  PRIMARY KEY (`category_id`)
);

create table category2event (
  event_id int(10) unsigned NOT NULL,
  category_id int(10) unsigned NOT NULL,

  PRIMARY KEY (`event_id`, category_id ),
  KEY `fkct_category_id` (`category_id`),
  CONSTRAINT `fk2_event_id` FOREIGN KEY (`event_id`) REFERENCES `event` (`event_id`),
  CONSTRAINT `fk2_category_id` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`)
);





insert into category( category_name ) values(       "Bildung" );
insert into category( category_name ) values(       "Bildung/Vortrag & Diskussion" );
insert into category( category_name ) values(       "Bildung/Konferenz & Workshop" );
insert into category( category_name ) values(       "Bühne" );
insert into category( category_name ) values(       "Bühne/Tanz" );
insert into category( category_name ) values(       "Bühne/Comedy & Kleinkunst" );
insert into category( category_name ) values(       "Bühne/Kinder" );
insert into category( category_name ) values(       "Bühne/Musical & Show" );
insert into category( category_name ) values(       "Bühne/Oper" );
insert into category( category_name ) values(       "Bühne/Schauspiel" );
insert into category( category_name ) values(       "Flohmarkt" );
insert into category( category_name ) values(       "Flohmarkt/Trödelmarkt" );
insert into category( category_name ) values(       "Flohmarkt/Nachtflohmarkt" );
insert into category( category_name ) values(       "Flohmarkt/Kinderflohmarkt" );
insert into category( category_name ) values(       "Freizeit" );
insert into category( category_name ) values(       "Freizeit/Bälle & Feste" );
insert into category( category_name ) values(       "Freizeit/Club & Party" );
insert into category( category_name ) values(       "Freizeit/Karneval" );
insert into category( category_name ) values(       "Freizeit/Kinder & Jugend" );
insert into category( category_name ) values(       "Freizeit/Messen & Märkte" );
insert into category( category_name ) values(       "Freizeit/Senioren" );
insert into category( category_name ) values(       "Freizeit/Tanz" );
insert into category( category_name ) values(       "Freizeit/Vereine & Verbände" );
insert into category( category_name ) values(       "Kunst & Literatur" );
insert into category( category_name ) values(       "Kunst & Literatur/Ausstellungen" );
insert into category( category_name ) values(       "Kunst & Literatur/Führungen" );
insert into category( category_name ) values(       "Kunst & Literatur/Lesungen" );
insert into category( category_name ) values(       "Musik" );
insert into category( category_name ) values(       "Musik/Chöre" );
insert into category( category_name ) values(       "Musik/Festivals" );
insert into category( category_name ) values(       "Musik/Jazz, Blues, Soul, Funk, Folk" );
insert into category( category_name ) values(       "Musik/Klassik" );
insert into category( category_name ) values(       "Musik/Rock & Pop" );
insert into category( category_name ) values(       "Musik/Metal & Punk" );
insert into category( category_name ) values(       "Musik/Schlager & Volksmusik" );
insert into category( category_name ) values(       "Politik" );
insert into category( category_name ) values(       "Politik/Lokalpolitik" );
insert into category( category_name ) values(       "Politik/Überregional" );
insert into category( category_name ) values(       "Sport" );
insert into category( category_name ) values(       "Sport/Mitmachen" );
insert into category( category_name ) values(       "Sport/Zuschauen" );


