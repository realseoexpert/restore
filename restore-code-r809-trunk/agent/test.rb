#!/usr/bin/env ruby

class ParsingTester
  require 'lib/restore_agent'
  require 'lib/restore_agent/xmlrpc/client'

  def initialize(file)
    @file = file
  end
  
  def run
    @server = RestoreAgent::XMLRPC::Client.new2("http://localhost:7777/")
    real_length = File.size(@file)
    begin
      ret = @server.call("agent.get_file", @file)

    rescue => e
      puts "error: #{e}\n#{e.backtrace.join("\n")}"
    end
    
  end
end


class WgetSpeedTester
  def initialize(file)
    @file = file
  end

  def run

    real_length = File.size(@file)
    begin
      #ret = @server.call("agent.get_file", f)
      req = "<?xml version=\"1.0\" ?><methodCall>
      <methodName>agent.get_file</methodName><params><param><value>
      <string>#{@file}</string>
      </value></param></params></methodCall>\n"

      File.open("/tmp/req", "w") do |f|
        f.write req
      end
      cmd = "wget -q --post-file /tmp/req --header 'Content-Type: text/xml' -O /dev/null http://localhost:7777/"
      system(cmd)
    rescue => e
      puts "error: #{e}\n#{e.backtrace.join("\n")}"
    end
  end
end


class WgetTester
  def initialize(file)
    @file = file
  end

  def run

    real_length = File.size(@file)
    begin
      #ret = @server.call("agent.get_file", f)
      req = "<?xml version=\"1.0\" ?><methodCall>
      <methodName>agent.get_file</methodName><params><param><value>
      <string>#{@file}</string>
      </value></param></params></methodCall>\n"

      File.open("/tmp/req", "w") do |f|
        f.write req
      end
      cmd = "wget -q --post-file /tmp/req --header 'Content-Type: text/xml' -O - http://localhost:7777/"
      IO.popen(cmd) do |ret|
        begin
          data = ret.read
          parser = XMLRPC::XMLParser::REXMLStreamParser.new
          ret = parser.parseMethodResponse(data)
          #puts ret.inspect
          
          if ret[1].length != real_length
            puts "Got : #{ret[1].length}, expected #{real_length}"
          end
        rescue => e
          puts e.to_s
          puts data.inspect
        end
      end

    rescue XMLRPC::FaultException => e
      puts "XMLRPC Fault: #{e.message}"
    rescue => e
      puts "some other error: #{e}\n#{e.backtrace.join("\n")}"
    end
  end
end


Dir.glob("/usr/bin/*").each do |f|
  next if File.directory?(f)
  next unless File.readable?(f)
  
  puts "Testing #{f}"
  
  ParsingTester.new(f).run
end

