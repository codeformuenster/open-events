require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'

module PartyalarmScraper
  class << self

    def delocalize_month(month)
      lookup_table = {
        'Januar': 1,
        'Februar': 2,
        'März': 3,
        'April': 4,
        'Mai': 5,
        'Juni': 6,
        'Juli': 7,
        'August': 8,
        'September': 9,
        'Oktober': 10,
        'November': 11,
        'Dezember': 12
      }
      lookup_table[month.to_sym]
    end

    def create_event_date(parsed_date, element)
      date_array = parsed_date.text.split[2..4]
      time_array = element.css('.veranstaltungsort')[0].children.first.text.split.first.split(":")

      year = date_array[2].to_i
      month = delocalize_month(date_array[1])
      day = date_array[0].to_i
      hour = time_array[0].to_i
      minutes = time_array[1].to_i

      DateTime.new(year, month, day, hour, minutes)
    end

    def create_event_name(element)
      element.css('.veranstaltungsname')[0].children[0].text
    end

    def create_event_location(element)
      location = {}
      location[:latitude] = ""
      location[:longitute] = ""
      location[:name] = element.css('.veranstaltungsort')[0].children[1].children.text
      location
    end

    def get_details_url(element)
      element.css('.veranstaltungsname')[0].children[0].attributes['href'].value
    end

    def parse_event_details_page(element)
          details_url = get_details_url(element)
          parse_page(details_url, '')
    end

    def create_event_image(description_page)
      image = {}
      image[:copyright] = ""
      img_tag = description_page.css('div .imtop a img')
      image[:url] = img_tag.empty? ? "" : img_tag.attr('src').value
      image
    end

    def collect_between(first, last)
      first == last ? [first] : [first, *collect_between(first.next, last)]
    end

    def parse_page(url, offset)
      url_with_offset = url + "#{offset*100}"
      page = HTTParty.get(url_with_offset)
      Nokogiri::HTML(page)
    end

    def create_event_description(description_page)
      start_description = description_page.css('hr')[0]
      event_description = collect_between(start_description, nil)
      event_description.shift
      event_description.pop
      event_description = event_description.map { |x| x.to_html }.join(" ")
    end

    def write_json_to_file(events)
      File.open(ARGV[0],"a") do |f|
        f.puts events
      end
    end

    def parse_events_of_dates(parsed_dates)
      events = []
      parsed_dates.each do |parsed_date|
        next_element = parsed_date.next_element

        loop do
          event = {}

          event[:id] = ""

          event_name =  create_event_name(next_element)
          event[:name] = event_name

          event_date = create_event_date(parsed_date, next_element)
          event[:startDate] = event_date

          event[:endDate] = ""

          event[:url] = get_details_url(next_element)

          parsed_event_details_page = parse_event_details_page(next_element)

          event_description = create_event_description(parsed_event_details_page)
          event[:description] = event_description

          event_image = create_event_image(parsed_event_details_page)
          event[:image] = event_image

          event_location = create_event_location(next_element)
          event[:location] = event_location

          event[:category] = ""
          event[:tags] = ""

          events << JSON.generate(event)

          next_element = next_element.next_element
          element_class = next_element.attributes['class'].value unless next_element.nil?
          break if element_class == 'eme_period' || element_class == nil
        end

        write_json_to_file(events)
      end
    end

    def start_scraper(url)
      offset = 1
      loop do
        parsed_page = parse_page(url, offset)
        parsed_dates = parsed_page.css('.eme_period')
        parse_events_of_dates(parsed_dates)

        next_page_exists = parsed_page.css('.eme_nav_right').first.attributes["href"].value != "#"
        break unless next_page_exists

        offset += 1
      end
    end
  end
end

url = 'http://muenster.partyphase.net/veranstaltungskalender-muenster/?eme_offset='

PartyalarmScraper.start_scraper(url)
