# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "net/http"
require "uri"
require "mechanize"
require "faraday"
require "rss"

class LogStash::Inputs::Crawler < LogStash::Inputs::Base
  config_name "crawler"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # The message string to use in the event.
  config :url, :validate => :string, :required => true

  #Set de interval for stoppable_sleep
  config :interval, :validate => :number, :default => 86400

  public
   def register
    @urls = []
    @agent = Mechanize.new
	  @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	  @blacklist = ['http://fusion.google.com/','yahoo.com','live.com','netvibes.com']
   end # def register


   def run(queue)
    # we can abort the loop if stop? becomes true
    while !stop?
      
      page = @agent.get(@url)
      page.links.each {|link|
            if link.href.chars.last(3).join == "xml" && not_include_blacklist(link)
              @urls << link.href
            end
      }
      
      links = @urls.uniq

      links.each { |l|
          response = Faraday.get l
          handle_response(response, queue)
      }

    Stud.stoppable_sleep(@interval) { stop? }
    end # loop
   end # def run


   def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accets)
    #  * cleanup temporary files
    #  * terminate spawned threads
   end

   def not_include_blacklist(link) 
      for i in 0..@blacklist.length-1
        if link.href.include?(@blacklist[i])
          return false
        end
      end
      return true
   end


   def handle_response(response, queue)
    body = response.body
    begin
      feed = RSS::Parser.parse(body)
      feed.items.each do |item|
        # Put each item into an event
        @logger.debug("Item", :item => item.author)
        handle_rss_response(queue, item)
      end
    rescue RSS::MissingTagError => e
      @logger.error("Invalid RSS feed", :exception => e)
    rescue => e
      @logger.error("Uknown error while parsing the feed", :exception => e)
    end
  end


  def handle_rss_response(queue, item)
    @codec.decode(item.description) do |event|
      event.set("Feed",  @url)
      event.set("published", item.pubDate)
      event.set("title", item.title)
      event.set("link", item.link)
      event.set("author", item.author)
      decorate(event)
      queue << event
    end
  end



end # class LogStash::Inputs::Crawler
