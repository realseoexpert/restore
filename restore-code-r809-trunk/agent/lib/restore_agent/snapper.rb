# obsolete, only here for reference
=begin
module RestoreAgent

  class Snapper
    require 'restore_agent/object_db'
    include DRbUndumped
    
    attr_reader :object_db
    
    def initialize(agent)
      @agent = agent
      @object_db = ObjectDB.new("/tmp/myobjects.db")
      puts "snapper initialized"
    end
    
    # mark objects for scanning.
    def prepare_objects(objects)
      @objects = objects
      return "OK"
    end

    def execute
      @objects.each_pair do |k,v|
        puts "Scanning #{k}"
        if o = @agent.root.find_object(k)
          begin
            # grab a reference to the receiver of this object on the master            
            modified = o.scan(self, v[:included], v[:receiver])
          rescue => e
            puts e.to_s
            puts e.backtrace.join("\n")
          end
        else
          puts "#{k} was not found!"
        end
      end
      @object_db.close            
    end
    
    def included?(object)
      if h = @objects[object.path]
        return h[:included]
      end
      return false
    end

    def excluded?(object)
      if h = @objects[object.path]
        return !h[:included]
      end
      return false
    end 
    
  end
  
end
=end