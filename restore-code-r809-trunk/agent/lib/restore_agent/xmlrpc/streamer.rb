=begin
module RestoreAgent
  module XMLRPC
    class Streamer
      BackpressureLevel = 50000
      ChunkSize = 16384
      #ChunkSize = 256
      include EventMachine::Deferrable
      def initialize connection, writer
        @connection = connection
        @response_writer = writer
        @http_chunks = false
        @size = 0
        @start = Time.now
      end

      def chunked?
        @http_chunks
      end

      def stream
        stream_one_chunk
      end

      def stream_one_chunk		  
        loop {
          begin
            data = @response_writer.read(ChunkSize)
          rescue => e
            puts e.to_s+e.backtrace.join("\n")
          end

          unless data.nil?
            # more data is available.
            if @connection.get_outbound_data_size > BackpressureLevel
              #puts "BACKPRESSURE"
              EventMachine::next_tick {stream_one_chunk}
              break
            else
              len = data.length
              @size += len

              @connection.send_data( "#{len.to_s(16)}\r\n" ) if @http_chunks

              puts "DATALENGTH: #{data.length}"  if $DEBUG
              puts "sending "+data if $DEBUG
              @connection.send_data(data)					  
              @connection.send_data("\r\n") if @http_chunks
            end
          else
            seconds = Time.now - @start
            rate = (@size / seconds.to_f)/1024.to_f
            #puts "xfer done: #{@size} in #{seconds}s: #{rate} kb/s"
            #puts "SUCCEED: #{@size}"
            @connection.send_data "0\r\n\r\n" if @http_chunks
            succeed
            break
          end
        }
      end
    end
  end
end
=end