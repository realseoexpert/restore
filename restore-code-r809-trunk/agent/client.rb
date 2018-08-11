require 'xmlrpc/client'
require 'pp'

server = XMLRPC::Client.new2("http://localhost:7777/")
result = server.call("agent.list_objects", "/")
pp result
