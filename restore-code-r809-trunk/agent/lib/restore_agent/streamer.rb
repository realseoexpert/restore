module RestoreAgent
  
  module Streamer
    require 'eventmachine'
    class Base
      BackpressureLevel = 50000
      ChunkSize = 16384

      include EventMachine::Deferrable

      def initialize(connection)
        @connection = connection
        @http_chunks = false
        @size = 0
        @start = Time.now
      end

      def chunked?
        @http_chunks
      end
      
      def stream		  
        loop do
          if @connection.get_outbound_data_size > BackpressureLevel
            # don't overfill. be patient
            EventMachine::next_tick {stream}
            break
          elsif data = read(ChunkSize) 
            # green light to generate more data
            len = data.length
            @size += data.length

            @connection.send_data( "#{len.to_s(16)}\r\n" ) if @http_chunks

            puts "DATALENGTH: #{data.length}"  if $DEBUG
            puts "sending "+data if $DEBUG
            @connection.send_data(data)					  
            @connection.send_data("\r\n") if @http_chunks
          else
            # no more data from read function.
            seconds = Time.now - @start
            rate = (@size / seconds.to_f)/1024.to_f
            puts "xfer done: #{@size} in #{seconds}s: #{rate} kb/s"
            #puts "SUCCEED: #{@size}"
            #@connection.send_data "0\r\n\r\n" if @http_chunks
            succeed
            break                        
          end
        end # loop
      end
      
      def read(size)
        #@response_writer.read(size)
        raise "abstract"
      end
      
    end # class Base
    
    class File < Base
      def initialize(connection, filename)
        super(connection)
        @filename = filename
        @file = ::File.new(filename, "r")
      end
      
      
      def read(size)
        @file.read(size)
      end
    end # class File
    
    class XMLRPCResponse < Base
      def initialize(connection, writer)
        super(connection)
        @writer = writer
      end

      def read(size)
        @writer.read(size)
      end
    end
    
    
  end
  
end