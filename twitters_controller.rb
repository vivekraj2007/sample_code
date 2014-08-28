   require 'twitter'
  require 'twitter_oauth'
class TwittersController < ApplicationController
  
  def twitter
  @id = params[:id]
   if !params[:page].blank?
     @page=params[:page]
 else
      @page = 1
  end
  #~ @client_followers = @client.followers(@page.to_i)
  @client_followers_all = @client.followers(@page.to_i)
     @client_followers = [];i=1;
   @client_followers_all.each do |twt|
       @client_followers <<  twt if i<=10
        i=i+1
   end
 # find_latest_tweets
  @homeheaderpart=Seo.find(:first,:select=>"title,description,keywords",:conditions=>["pagename LIKE ?","Twitter"])
end
  
  
  #methof for tweets partial
 def latest_tweets
 find_latest_tweets
 render :partial => 'latest_tweets', :layout=>false and return
end

#method fro finding latest tweets
def find_latest_tweets
   @client_flrs_all = @client.friends_timeline(:count => 30)
   @client_flrs = [];i=1;
   @client_flrs_all.each do |twt|
       @client_flrs <<  twt if i<=10
        i=i+1
   end
 end
  
  
  
  
  #searching for following of the inkakinada
 def search_followers
     client = TwitterOAuth::Client.new(
    :consumer_key => '****',
    :consumer_secret => '****',
    :token => '****', 
    :secret => '***'
)
@client_followers=[]
 client.all_followers.each do |rec|
     if !params[:mysearch].blank? && (rec["name"].include?(params[:mysearch]) || rec["name"].downcase.include?(params[:mysearch]) || rec["name"].upcase.include?(params[:mysearch]))
     @client_followers <<  rec
  end
  end
   if !@client_followers.blank?
    render :partial => 'search_followers',:locals => {:client_followers => @client_followers}, :layout => false and return
  end
 render :partial => 'blank' and return
end
 
 
 def close_block
  render :partial => "close_block" , :layout => false and return
end
 

 
 
#method for connecting twitter API
def twitter_connect
   @client = TwitterOAuth::Client.new(
    :consumer_key => '*****',
    :consumer_secret => '*****',
    :token => '*****', 
    :secret => '*****'
)
end
  
  
  
  
  
  
  
  
  
  
  
  
  
end
