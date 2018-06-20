# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname

# Generate a repeating message.
#
# This plugin is intented only as an example.

class LogStash::Inputs::Crawler < LogStash::Inputs::Base
  config_name "crawler"

  # If undefined, Logstash will complain, even if codec is unused.
  #default :codec, "plain"
  default :codec, "plain"

  #Entry point URL
  #config :init_url, :validate => :string, :required => true

  #The max deph the plugin should reach
  #config :max_deph, :validate => :number, :default => 3

  # The message string to use in the event.
  config :message, :validate => :string, :default => "Hello World!"

  # Set how frequently messages should be sent.
  #
  # The default, `1`, means send a message every second.
  config :interval, :validate => :number, :default => 1

  #EXAMPLE reddit tag
  #config :subreddit, :validate => :string, :default => 'elastic'

  public
  def register
    @host = Socket.gethostname
    #@http = Net::HTTP.new('reddit.com', 443)
    #@get = Net::HTTP::Get.new("/r/#{@subreddit}/.json")
    #@http.use_ssl = true
  end # def register

  def run(queue)
    # we can abort the loop if stop? becomes true
    while !stop?
      event = LogStash::Event.new("message" => @message, "host" => @host)
      decorate(event)
      queue << event
      # because the sleep interval can be big, when shutdown happens
      # we want to be able to abort the sleep
      # Stud.stoppable_sleep will frequently evaluate the given block
      # and abort the sleep(@interval) if the return value is true
      Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  end # def run

  #def run(queue)
    # we can abort the loop if stop? becomes true
   # while !stop?
     # response = @http.request(@get)

      #########################################################################################################
      #event = LogStash::Event.new('web_content' => response)

      #decorate(event)

      #queue << event
      #########################################################################################################


      #json = JSON.parse(response.body)

      #json['data']['children'].each do |child|

        #event = LogStash::Event.new('message' => child, 'host' => @host, 'web_content' => response)

        #decorate(event)

        #queue << event

      #end

      #Stud.stoppable_sleep(@interval) { stop? }

      # event = LogStash::Event.new("message" => @message, "host" => @host)
      # decorate(event)
      # queue << event
      # # because the sleep interval can be big, when shutdown happens
      # # we want to be able to abort the sleep
      # # Stud.stoppable_sleep will frequently evaluate the given block
      # # and abort the sleep(@interval) if the return value is true
      # Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  #end # def run

  def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accepts)
    #  * cleanup temporary files
    #  * terminate spawned threads
  end
end # class LogStash::Inputs::Crawler
