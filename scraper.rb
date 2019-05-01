require 'scraperwiki'
require 'mechanize'

case ENV['MORPH_PERIOD']
  when 'lastmonth'
  	period = "lastmonth"
  when 'thismonth'
  	period = "thismonth"
  else
    period = "thisweek"
    ENV['MORPH_PERIOD'] = 'thisweek'
end
puts "Getting data in `" + ENV['MORPH_PERIOD'] + "`, changable via MORPH_PERIOD environment"

starting_url = 'https://eservices.northernbeaches.nsw.gov.au/ePlanning/live/Public/XC.Track/SearchApplication.aspx?d=' + period + '&k=LodgementDate&t=DevApp'
comment_url = 'mailto:council@northernbeaches.nsw.gov.au?subject='

def clean_whitespace(a)
  a.gsub("\r", ' ').gsub("\n", ' ').squeeze(" ").strip
end

def extract_addresses!(bits)
  addresses = []
  bits.each_with_index do |line, index|
    if /\r\n\t\t\t\t\t\t\t\t\tAddress:\r\n\t\t\t\t\t\t\t\t\t <strong>(.*)<\/strong>/.match(line)
      addresses << clean_whitespace(line.match(/<strong>(.*)<\/strong>/)[1])

      bits.delete_at(index)
    end
  end
  addresses
end

def extract_date!(bits)
  date  = nil
  bits.each_with_index do |line, index|
    if /(\d\d)\/(\d\d)\/(\d\d\d\d)/.match(line)
      m = line.match(/(\d\d)\/(\d\d)\/(\d\d\d\d)/)
      date = Date.new(m[3].to_i, m[2].to_i, m[1].to_i).to_s

      bits.delete_at(index)
    end
  end
  date
end

def scrape_table(doc, comment_url)

  doc.search('.result')[1..-1].each do |tr|
    bits = tr.to_s.split("<br>")
    addresses = extract_addresses!(bits) # modifies bits to remove address lines from array
    date_received = extract_date!(bits)

    record = {
      'council_reference' => clean_whitespace(tr.at('a').inner_text),
      'address'           => addresses.first,
      'description'       => clean_whitespace(bits[2]),
      'info_url'          => (doc.uri + tr.at('a')['href']).to_s,
      'comment_url'       => comment_url + CGI::escape("Development Application Enquiry: " + clean_whitespace(tr.at('a').inner_text)),
      'date_scraped'      => Date.today.to_s,
      'date_received'     => date_received
    }

    puts "Saving record " + record['council_reference'] + " - " + record['address']
#       puts record
    ScraperWiki.save_sqlite(['council_reference'], record)
  end
end

agent = Mechanize.new
doc = agent.get(starting_url)

scrape_table(doc, comment_url)
