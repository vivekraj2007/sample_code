require "mechanize"

class Cart < ActiveRecord::Base
  
  attr_accessor :lat,:longt,:loct,:map_title,:map_subt, :bpage, :cat_id, :country, :state,:location, :continent, :map_page

  
  attr_accessor :browser_ip, :browser_lat, :browser_longt
  
  
  def self.get_browser_details_with_lat_longt(ip)
  agent = WWW::Mechanize.new
  agent.user_agent_alias = 'Mac FireFox'
 
  page = agent.get("http://whatismyipaddress.com/staticpages/index.php/lookup-ip")
  page.forms[2].fields[0].value = "#{ip}"
  data = agent.submit(page.forms[2])
  page = (data/"table[1]/tr/td[3]")

  lat = (page/"tr[4]/").inner_html
  longt = (page/"tr[5]/").inner_html
  country = (page/"tr[3]/").inner_html
  if !lat.blank? && !longt.blank? && !country.blank?
  return  lat.split(':')[-1].to_f, longt.split(':')[-1].to_f, country.split(':')[-1].to_s    
  else
  return nil
end

  rescue Exception => e
  return nil
  end


end
