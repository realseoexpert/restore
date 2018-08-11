module RestoreAgent::XMLRPC
  
  class Base64Stream

    def initialize(src)
      @src = src
      @encoded_buffer = ''
      @stream_done = false
      puts "new stream"
    end

    def read(size=1024)
      return nil if @stream_done && @encoded_buffer.empty?
      
      while !@stream_done &&
        (need = (size - @encoded_buffer.length)) > 0
        # we need 'need' bytes in @encoded_buffer.

        binary_size = ((need*3)/4.to_f).ceil
        remainder = binary_size % 3      
        binary_size += 3-remainder if remainder
        

        # we need binary_size from src
        if data = @src.read(binary_size)
          if data.length < binary_size
            puts "short read"
          end
          @encoded_buffer += [data].pack("m").gsub(/\n/, '')
        else
          # stream done.
          puts "done"
          @stream_done = true
          break
        end
      end

      ret = @encoded_buffer[0..(size-1)]
      # truncate buffer
      @encoded_buffer[0..(size-1)] = ''

      return ret

    end
  end
  
  class Tag
    def initialize(name, txt)
      @name, @txt = name, txt
      @rendered = false
      
    end
    
    def render
      if @txt.empty?
        "<#{@name}/>"
      else
        cleaned = @txt.dup
        cleaned.gsub!(/&/, '&amp;')
        cleaned.gsub!(/</, '&lt;')
        cleaned.gsub!(/>/, '&gt;')
        "<#{@name}>#{cleaned}</#{@name}>"
      end      
    end
    
    def read(size=1024, &block)
      # for now, be a bad citizen and render all.
      if @rendered
        yield nil
      else
        yield render
        @rendered = true
      end
    end
    
  end
  
  
  class FileTag
    def initialize(name, file)
      @name, @file = name, file
      @buffer = ''
      @render_state = :begin
      @pos = 0
      @bpos = 0
      @obuffer = ''
    end
    
    def render

      f = @file
        
      txt = ''#f.read
      if txt.empty?
        "<#{@name}/>"
      else
        encoded = [txt].pack("m")
        "<#{@name}>#{encoded}</#{@name}>"
      end 

    end
    
    def read(size=1024, &block)
      while (@buffer.length < size) && (@render_state != :closed)
        puts "element #{@name} read() buffer loop"  if $DEBUG
        # get more data
        case @render_state
        when :begin
          
          @buffer += "<#{@name}>"
          @render_state = :contents
          @file = File.new(@file.path) if @file.closed? #might need a reopen
          @b64 = Base64Stream.new(@file)
        when :contents
          puts "contents on #{@file.path}: #{@pos}" if $DEBUG
          puts "buffer length: #{@buffer.length}" if $DEBUG
          
          begin
            if @file.closed?
              puts "reopening"
              @file = File.new(@file.path, "r")
              @b
              @file.seek(@pos)
            end
          rescue => e
            puts e.to_s
          end
          
          if data = @b64.read(size-@buffer.length)
            @pos = @file.tell
            @buffer += data
          else
            puts "closed" if $DEBUG
            @file.close
            @render_state = :closing            
          end
        when :closing
          puts "in closing" if $DEBUG
          #puts "real: #{@pos}, base64: #{@bpos} #{@bpos/@pos.to_f}"
          @buffer += "\n</#{@name}>"
          @render_state = :closed
        end
      end
        
     
      if (@render_state == :closed) && @buffer.empty?
        # all done
        puts "all done" if $DEBUG
        yield nil
      else
        # grab a chunk of the specified size
        puts "old buffer size: #{@buffer.length}" if $DEBUG
        ret = @buffer[0..(size-1)]
        # truncate buffer
        @buffer[0..(size-1)] = ''
        puts "yielding size: #{ret.length}, new buffer size: #{@buffer.length}" if $DEBUG
        
        puts "element #{@name} yielding: #{ret}" if $DEBUG
        yield(ret)
      end
    end    
  end
  
  
  
  class Element
    def initialize(name, *children)
      @name = name
      @children = children
      
      @buffer = ''
      @render_index = 0
      @render_started = false
      @render_done = false
    end

    def <<(val)
      @children << val
    end

    def render_start
      if @children.empty?
        "<#{@name}/>"
      else
        "<#{@name}>"
      end
    end

    def render_end
      if @children.empty?
        ""
      else
        "</#{@name}>"
      end
    end
    
    def read(size=1024, &block)
      puts "element #{@name} read start" if $DEBUG
      begin
        # read 'size' rendered bytes from the tree.
        while (@buffer.length < size) && !@render_done
          puts "element #{@name} read() buffer loop"  if $DEBUG
          # get more data
          if !@render_started
            @buffer = render_start
            @render_started = true
          end

          if !@children.empty?
            puts "element #{@name} read() buffer loop 2"  if $DEBUG
            if c = @children[@render_index]
              puts "element #{@name} read() buffer loop 3"  if $DEBUG
              
              # read enough from this child.
              if c.is_a?(Array)
                puts "ARRAY!"
                @render_index += 1
                next
              end # c.is_a?

              c.read(size - @buffer.length) do |data|
                puts "element #{@name} read() buffer.c.read loop #{@render_index}" if $DEBUG
                if data.nil?
                  # this object is done. set marker to the next object
                  @render_index += 1
                else
                  puts "element #{@name} adding data to buffer: #{data}" if $DEBUG
                  @buffer += data
                end
              end # c.read

            else
              # no more child objects
              puts "element #{@name} no more child objects" if $DEBUG
              @buffer += render_end
              @render_done = true
            end
          else
            # no children ever existed.
            @render_done = true
            
          end # !@children.empty?
        end
        
        if @render_done && @buffer.empty?
          # all done
          yield nil
        else
          # grab a chunk of the specified size
          ret = @buffer[0..(size-1)]
          # truncate buffer
          @buffer[0..(size-1)] = ''
          puts "element #{@name} yielding: #{ret}" if $DEBUG
          yield(ret)
        end
      rescue => e
        puts "element #{@name} read rescued:"
        puts e.to_s+e.backtrace.join("\n")
      end


    end
  end

  def self.conv2value(param)
      val = case param
    when Fixnum 
      Tag.new("i4", param.to_s)

    when Bignum
      if ::XMLRPC::Config::ENABLE_BIGINT
        Tag.new("i4", param.to_s)
      else
        if param >= -(2**31) and param <= (2**31-1)
          Tag.new("i4", param.to_s)
        else
          raise "Bignum is too big! Must be signed 32-bit integer!"
        end
      end
    when TrueClass, FalseClass
      Tag.new("boolean", param ? "1" : "0")

    when String 
      Tag.new("string", param)

    when Symbol 
      Tag.new("string", param.to_s)

    when NilClass
      #if ::XMLRPC::Config::ENABLE_NIL_CREATE
        Element.new("nil")
      #else
      #  raise "Wrong type NilClass. Not allowed!"
      #end

    when Float
      Tag.new("double", param.to_s)

    when Struct
      h = param.members.collect do |key| 
        value = param[key]
        Element.new("member", 
          Tag.new("name", key.to_s),
          conv2value(value) 
        )
      end

      Element.new("struct", *h) 

    when Hash
      # TODO: can a Hash be empty?

      h = param.collect do |key, value|
        Element.new("member", 
        Tag.new("name", key.to_s),
        conv2value(value) 
        )
      end

      Element.new("struct", *h) 

    when Array
      # TODO: can an Array be empty?
      a = param.collect {|v| conv2value(v) }

      Element.new("array", 
      Element.new("data", *a)
      )

    when Time, Date, ::DateTime
      Tag.new("dateTime.iso8601", param.strftime("%Y%m%dT%H:%M:%S"))  

    when ::XMLRPC::DateTime
      Tag.new("dateTime.iso8601", 
      format("%.4d%02d%02dT%02d:%02d:%02d", *param.to_a))

    when ::XMLRPC::Base64
      Tag.new("base64", param.encoded) 
    when ::File
      #puts "XXX NEW FILE OBJECT! WATCH IT GO! WHEEEEEEEEEEEEEE" if $DEBUG
      FileTag.new("base64", param)
    else 
      if ::XMLRPC::Config::ENABLE_MARSHALLING and param.class.included_modules.include? ::XMLRPC::Marshallable
        # convert Ruby object into Hash
        ret = {"___class___" => param.class.name}
        param.instance_variables.each {|v| 
          name = v[1..-1]
          val = param.instance_variable_get(v)

          if val.nil?
            ret[name] = val if ::XMLRPC::Config::ENABLE_NIL_CREATE
          else
            ret[name] = val
          end
          }
          return conv2value(ret)
        else 
          ok, pa = false #wrong_type(param)
          if ok
            return conv2value(pa)
          else 
            raise "Wrong type!"
          end
        end
      end

      Element.new("value", val)
    end

end