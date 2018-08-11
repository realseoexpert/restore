module RestoreAgent
  module XMLRPC
    require "xmlrpc/server"
    require 'restore_agent/xmlrpc/element'
    require 'restore_agent/xmlrpc/writer'
    
    class Server < ::XMLRPC::BasicServer
      def initialize(http_server)
        super()
        @http_server = http_server
      end
      
      def spool_file(*args)
        @http_server.spool_file(*args)
      end
      
      public :call_method
      
    end # class Server
  end
end