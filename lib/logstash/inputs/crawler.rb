# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "set"
require "uri"
require "nokogiri"
require "open-uri"

class LogStash::Inputs::Crawler < LogStash::Inputs::Base
  config_name "crawler"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # The message string to use in the event.
  config :url, :validate => :string, :required => true

  #Set de interval for stoppable_sleep 
  config :interval, :validate => :number, :default => 200

  public
  def register
        @seen_pages = Set.new                      # Keep track of what we've seen
  end # def register


  def run(queue)
    # we can abort the loop if stop? becomes true
    while !stop?

        crawl_site(@url) do |page,uri|
          event = LogStash::Event.new("link" => uri.to_s)
	        decorate(event)
       		queue << event
        end

        evento = LogStash::Event.new("paginas_exploradas" => @seen_pages.length)
	      decorate(evento)
       	queue << evento

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

  def crawl_site( starting_at, &each_page )
        files = %w[png jpeg jpg gif svg txt js css zip gz asp html htm PNG JPEG JPG GIF SVG TXT JS CSS ZIP GZ ASP HTML HTM]
        starting_uri = URI.parse(starting_at)
      
        crawl_page = ->(page_uri) do              # A re-usable mini-function
          unless @seen_pages.include?(page_uri)
            @seen_pages << page_uri                # Record that we've seen this
            begin
              doc = Nokogiri.HTML(open(page_uri)) # Get the page
              each_page.call(doc,page_uri)        # Yield page and URI to the block
      
              # Find all the links on the page
              hrefs = doc.css('a[href]').map{ |a| a['href'] }

              # Make these URIs, throwing out problem ones like mailto:
              uris = hrefs.map{ |href| URI.join( page_uri, href ) rescue nil }.compact.uniq
      
              # Pare it down to only those pages that are on the same site
              uris.select!{ |uri| uri.host == starting_uri.host }

              # Throw out links to files (this could be more efficient with regex)
              uris.reject!{ |uri| files.any?{ |ext| uri.path.end_with?(".#{ext}") } }
      
              # Remove #foo fragments so that sub-page links aren't differentiated
              uris.each{ |uri| uri.fragment = nil }
      
              # Recursively crawl the child URIs
              uris.each{ |uri| crawl_page.call(uri) }
      
            rescue OpenURI::HTTPError # Guard against 404s
              warn "Skipping invalid link #{page_uri}"
            end
          end
        end
        crawl_page.call( starting_uri )   # Kick it all off!
  end
      

end # class LogStash::Inputs::Crawler
