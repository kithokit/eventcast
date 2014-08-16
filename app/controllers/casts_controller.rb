require 'koala'
require 'twitter'
require 'json'
require 'rest_client'
require 'json'
require 'date'

class CastsController < ApplicationController

  def index
    render 'welcome'
  end

  def nth
    render :text => "I'm a text"
  end

  def login
    render 'index'
  end

  def postcast
    @title = params["title"]
    @day = params["date"]
    @time1 = params["time1"]
    @time2 = params["time2"]
    @events = find_events
    @starttime = epochtime(params["date"], params["time1"])
    @endtime = epochtime(params["date"], params["time2"])
    @duration = @endtime.to_i - @starttime.to_i
    @desc = params["desc"]
    @msg = params["msg01"]
    @url = create_event(@starttime, @duration, @events.last, @desc , params["title"])
    if params["checkbox-1"].eql? "on"
      post_facebook(fb_message)
    end
    if params["checkbox-2"].eql? "on"
      post_twitter(t_message)
    end
    render 'thanks'
  end

  def thanks
    render 'thanks'
  end

  def fb_message
    c =  <<EOF
    #{@title} by #{@events.last["name"]}
    ---------------------------------------------------
    #{@msg}
    #{@title}
    #{@day} From #{@time1} to #{@time2}
    Description:
    #{@desc}
    ----------------------------------------------------
    Please sign up here
    #{@url}
EOF
    c
  end

  def t_message
    d =  <<EOF
    #{@title} by #{@events.last["name"]} on #{@day} from #{@time1} to #{@time2}. Please sign up here #{@url}
EOF
    d
  end

  def epochtime(date, time)
    datearray = date.split("-").map {|r| r.to_i}
    timearray = time.split(":").map {|r| r.to_i}
    DateTime.new(datearray[0],datearray[1],datearray[2],timearray[0],timearray[1],0,'-7').strftime('%Q')
  end

  def castout
    @events = find_events.map { |r| r["name"] }
    render "post"
  end

  def find_events
    apikey = APP_CONFIG["MEETUP_API"]
    member_id = APP_CONFIG["MEETUP_MEMBERID"]
    url = "http://api.meetup.com/2/groups"
    res = JSON.parse(RestClient.get url, {:params => {
        :organizer_id => member_id,
        :key => apikey,
    }})
    res["results"]
  end

  def create_event(starttime, duration, meetup_group, desc, name)
    apikey = APP_CONFIG["MEETUP_API"]
    url = "http://api.meetup.com/2/event"
    params = {
      :group_id => meetup_group["id"],
      :group_urlname => meetup_group["link"],
      :name => name,
      :key => apikey,
      :description => desc,
      :time => starttime,
      :duration => duration,
    }
    res = JSON.parse(RestClient.post url, params)
    res["event_url"]
  end

  def post_facebook(message)
    key =  APP_CONFIG["FACEBOOK_KEY"]
    @graph = Koala::Facebook::API.new(key)
    accounts = @graph.get_connections("me", "accounts")
    keypage = accounts.first["access_token"]
    pageid = accounts.first["id"]
    @graph = Koala::Facebook::API.new(keypage)
    @graph.put_object(pageid, "feed", :message => message)
  end

  def post_twitter(message)
    client = Twitter::REST::Client.new do |config|
      conkey = APP_CONFIG["TWITTER_CONKEY"]
      consec = APP_CONFIG["TWITTER_CONSEC"]
      acctoken  = APP_CONFIG["TWITTER_ACCESS"]
      accsec = APP_CONFIG["TWITTER_SEC"]
      config.consumer_key = conkey
      config.consumer_secret = consec
      config.access_token = acctoken
      config.access_token_secret = accsec
    end
    client.update(message)
  end
end
