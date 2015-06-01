var cheerio = require('cheerio');
    request = require('request');
    url = 'http://www.fzw.de/programm/'



request(url, function (error, response, body) {
	if (!error) {
  	var $ = cheerio.load(body);
  	$('div[style="position: relative; background: url(img/blank.gif);"] > a').each(function(i, element) {
      eventUrl = "http://www.fzw.de/"+ $(this).attr('href');
      request(eventUrl, function (error, response, body) {
      	if (!error) {
          var $ = cheerio.load(body);
          var eventDate = $('.bigBox > h2:first-of-type').text();
          eventDate = eventDate.substring(4);
          var eventDetails = $('.bigBox > h2:nth-of-type(3)').text();
          var eventDetailsRegEx = /Beginn: (\d\d.\d\d)/;
          var eventDetailsResult = eventDetails.match(eventDetailsRegEx);
          if (eventDetailsResult !== null) var eventStartTime = eventDetailsResult[1];
          var eventName = $('.bigBox > h3:first-of-type').text().trim();
          $('.bigBox > div:nth-of-type(2) > *').each(function() {
            var content = $(this).text();
            $(this).replaceWith(content);
          });
          var eventDescription = ($('.bigBox > div:nth-of-type(2)').text().trim());
          var eventJSON = {
            "@context": "http://schema.org",
            "@type": "Event",
            "name": eventName,
            "description": eventDescription,
            "location": {
              "@type": "Place",
              "address": {
                "@type": "PostalAddress",
                "streetAddress" : "Ritterstr. 20",
                "addressLocality" : "Dortmund",
                "postalCode" : "44137"
                }
              },
            "startDate": eventDate + eventStartTime,
            "url": eventUrl
          }

          console.log(JSON.stringify(eventJSON));
        } else {
      		console.log("Event HTTP Request fehlgeschlagen: " + error);
      	}
      });
    });
  } else {
		console.log("Übersicht HTTP Request fehlgeschlagen: " + error);
	}



});
