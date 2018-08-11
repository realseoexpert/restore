#!/usr/bin/env ruby


$: << './lib'
require 'restore_agent'
require 'restore_agent/xmlrpc/server'
require 'restore_agent/handler/agent'


xmlrpc_request = "<?xml version=\"1.0\" ?><methodCall>
  <methodName>agent.get_file</methodName><params><param><value>
  <string>/bin/vdir</string>
  </value></param></params></methodCall>\n"
  
@rpc_server = RestoreAgent::XMLRPC::Server.new
@rpc_server.add_handler("agent", RestoreAgent::Handler::Agent.new(@rpc_server))
@rpc_server.set_default_handler do |name, *args|
  raise XMLRPC::FaultException.new(-99, "Method #{name} missing or wrong number of parameters!")
end

writer = @rpc_server.process(xmlrpc_request)
response = ''
while data = writer.read
  puts data
  response += data
end


parser = XMLRPC::XMLParser::REXMLStreamParser.new
parser.parseMethodResponse(response)
