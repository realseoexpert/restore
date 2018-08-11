
module RestoreAgent
  #require 'drb'

  require 'restore_agent/http'
  require 'restore_agent/streamer'
  require 'restore_agent/xmlrpc/server'
  require 'restore_agent/handler/agent'
  require 'restore_agent/handler/snapshot'


  module Server
    # Creates a new server module
    def self.new
      Module.new do
        # include the HTTP state machine and everything else
        include RestoreAgent::HTTP::Server
        include RestoreAgent::Server
        
        # define a start method for starting the server
        def self.start(addr, port)
          EventMachine::run do
            EventMachine::start_server addr, port, self
          end
        end

        # setup the spool of waiting files.
        @@spool = {'ffabjiofg' => '/proc/partitions'}
        
        # the rpc server is in the global context, but the parser is not.
        # The reason for this is that the server's handlers may change due to
        # running processes such as snapshots, and those changes must be persistent
        # across connections.  The parser is specific to the connection.
        @@rpc_server = RestoreAgent::XMLRPC::Server.new(self)
        @@rpc_server.add_handler("agent", RestoreAgent::Handler::Agent.new(@@rpc_server))
        @@rpc_server.set_default_handler do |name, *args|
          raise ::XMLRPC::FaultException.new(-99, "Method #{name} missing or wrong number of parameters!")
        end

        def self.spool_file(key, path)
          @@spool[key.to_s] = path
          return key
        end      
        
        
        # invoke the supplied block for application-specific behaviors.
        #yield
      end
    end
    

    
    def handle(request)
      # easy shortcut to xmlrpc requests
      begin
        content_type = parse_content_type(request.headers[:content_type]).first rescue ''
        if (request.path == "/test") || (content_type == "text/xml")

          xmlrpc_request = ''
          if request.path != "/test"
            # require POST
            return RestoreAgent::HTTP::Response.new(
            :status => 405, :body => "Method Not Allowed") unless request.method == :post

            # need some POST data!
            return RestoreAgent::HTTP::Response.new(
            :status => 411, :body => "Length Required") unless request.content_length > 0

            xmlrpc_request = request.body
          else
            # fabricate for testing
            xmlrpc_request = "<?xml version=\"1.0\" ?><methodCall>
            <methodName>agent.get_file</methodName><params><param><value>
            <string>/bin/vdir</string>
            </value></param></params></methodCall>\n"
          end

          # XXX move to where it's needed.
          unless @rpc_parser
            @rpc_parser = ::XMLRPC::XMLParser::REXMLStreamParser.new
          end

          resp = RestoreAgent::HTTP::Response.new(:status => 200, :content_type => "text/xml; charset=utf-8")
          method, params = @rpc_parser.parseMethodCall(xmlrpc_request) 
          
          writer = XMLRPC::ResponseWriter.new(*@@rpc_server.call_method(method, *params))

          streamer = Streamer::XMLRPCResponse.new(self, writer)
          streamer.callback do
            set_state(:state_done)
          end
          resp.streamer = streamer

          return resp
        elsif request.path =~ /spool\/(.+)$/
          key = $1
          puts "request for #{key} from spool"
          #filename = $1
          #filename = '/'+$1
          #puts filename
          #if File.readable?(filename)
          if path = @@spool[key]
            resp = RestoreAgent::HTTP::Response.new(:status => 200, :content_length => File.size(path))
            streamer = RestoreAgent::Streamer::File.new(self, path)
            resp.streamer = streamer
            streamer.callback do
              set_state(:state_done)
            end
            return resp
          end
        end
      rescue => e
        puts e.to_s+e.backtrace.join("\n")
      end
      return RestoreAgent::HTTP::Response.new(:status => 404, :body => "Not found")
      
    end # def handle
  end    



end