var cheerio = require('cheerio');
    request = require('request');
    url = 'http://www.fzw.de/programm/'

request(url, function (error, response, body) {
	if (!error) {
  	var $ = cheerio.load(body);
    bigBox = $('.bigBox').html();
    $ = cheerio.load(bigBox);
  	$('div[style="position: relative; background: url(img/blank.gif);"]').each(function() {

      eventBlob = $(this).html();
      $ = cheerio.load(eventBlob);
      console.log($('table > tr > td > h3').text().trim());
      console.log($('table > tr > td[style="width: 85px; vertical-align: top;"] > h2').text().trim());
      console.log($('table > tr > td > span').text().trim());
      console.log($('.programEventInfo > table > tr > td:last-child').text().trim());
      console.log("---")
    });
  } else {
		console.log("HTTP Request fehlgeschlagen: " + error);
	}
});
