require 'net/http'
require 'open-uri'
require 'nokogiri'

namespace :marc_codes do

desc "fetch marc geographic codes, write solrmarc-style translation properties to stdout"
task :geographic do
  html = Nokogiri::HTML(open("http://www.loc.gov/marc/geoareas/gacs_code.html").read)

  puts "# Translation map for marc geographic codes constructed by rake marc_codes:geographic task"
  puts "\n\n\n"
  html.css("tr").each do |line|
    code = line.css("td.code").inner_text.strip
    unless code.blank?
      code.gsub!(/^\-/, '') # treat discontinued code like any other
  
      label = line.css("td[2]").inner_text.strip
  
      puts "#{code} = #{label}"
    end
  end
  
end

end


