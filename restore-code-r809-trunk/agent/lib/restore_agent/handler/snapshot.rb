module RestoreAgent::Handler
  class Snapshot

    require 'restore_agent/object/base'
    require 'restore_agent/object/root'
    require 'restore_agent/object/filesystem'
    require 'restore_agent/object/file'
    require 'restore_agent/object/directory'
    require 'restore_agent/object/mysql_server'
    require 'restore_agent/object_db'
    
    attr_reader :root
    attr_reader :object_db

    def initialize(server, id, object_config)
      @server, @id, @object_config = server, id, object_config
      @root = RestoreAgent::Object::Root.new
      @object_db = RestoreAgent::ObjectDB.new("/tmp/myobjects.db")
      
      @done_scanning = false
      
      @queue = SizedQueue.new(1)
      
      # can we say, create a scanning thread here?
      @scan_thread = Thread.new do
        scan_objects
        @done_scanning = true
      end
      @executions = 0
    end
    
    def execute
      @executions += 1
      puts "Execute: #{@id} #{@executions}"
      begin
        if o = @queue.pop
          #puts "returning o: #{o.inspect}"
          o.delete(:io) if o[:io].nil?
          puts o.inspect
          return o
        elsif @done_scanning
          puts "DONE"
          @scan_thread.join
          return "DONE"
        else
          #return "DONE" if @done_scanning
          puts "WAIT"
          return "WAIT"
        end
      rescue ThreadError
        return "DONE"
      rescue => e
        puts "#{e.class}: #{e}\n#{e.backtrace.join('\\n')}"
        return "FAIL"
      end
      return "WHAT"
    end
    
    
    # XXX block access from xmlrpc!
    def scan_objects
      begin
        @object_config.each_pair do |k,v|
          puts "Scanning from config: #{k}"
          if o = @root.find_object(k)
            begin
              modified = o.scan(self, v['included'])
            rescue => e
              puts e.to_s
              puts e.backtrace.join("\n")
            end
          else
            puts "#{k} was not found!"
          end
        end
      rescue => e
        puts "#{e}\n#{e.backtrace.join('\n')}"
      end
      #@object_db.close      
      @done_scanning = true
    end
    
    # XXX block access from xmlrpc!
    # accept objects to enqueue
    def update_data(path, event, container, attrs, io)
      #puts "update_data(#{event}, #{container}, #{attrs}, #{io.class})"
      # throw it in queue
      key = @server.spool_file(Time.now.usec, io.path) if io 
      #puts [e,e.backtrace].flatten.join("\n")
      o = {
        :path => path,
        :event => event,
        :container => container,
        :attrs => attrs
      }
      o[:data_href] = "/spool/#{key}" if io
      @queue << o
      
    end

  end
end