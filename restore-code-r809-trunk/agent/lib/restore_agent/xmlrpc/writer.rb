module RestoreAgent::XMLRPC
  require 'restore_agent/xmlrpc/element'

  class ResponseWriter
    def initialize(is_ret, *params)
      
      # prime the buffer
      @buffer = '<?xml version="1.0" ?>'

      # build the ENTIRE xml response tree in memory with the 
      # given params.
      if is_ret
        resp = params.collect do |param|
          Element.new("param", RestoreAgent::XMLRPC.conv2value(param))
        end

        resp = Element.new("params", *resp)
      else
        if params.size != 1 or params[0] === XMLRPC::FaultException
          raise ArgumentError, "no valid fault-structure given"
        end
        resp = Element.new("fault", RestoreAgent::XMLRPC.conv2value(params[0].to_h))
      end
      
      @root = Element.new("methodResponse", resp)
      #puts "Tree: #{@root.inspect}"
    end

    # streaming stuff
    # This is basically a read function in order to get any part of the
    # xml response tree to act like an IO object.
    def read(size=1024)
      #puts "writer read"
      # get 'size' bytes out of our buffer.
      begin
        if @buffer.length < size
          # get more data

          @root.read(size-@buffer.length) do |data|
            if data.nil?
              # done!
            else
              #puts "adding element read data! #{data}"
              @buffer += data
            end
          end
        end

        # grab a chunk of the specified size
        ret = @buffer[0..size-1]
        if ret.empty?
          # all done
          #puts "writer done"
          return nil
        else
          # truncate buffer
          #puts "writer read returning data"
          @buffer[0..size-1] = ''
          return ret
        end
      rescue => e
        puts "writer read() rescued"
        return nil
      end
    end

  end
end