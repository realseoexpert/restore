module RestoreAgent::Handler
  class Agent

    require 'restore_agent/object/base'
    require 'restore_agent/object/root'
    require 'restore_agent/object/filesystem'
    require 'restore_agent/object/file'
    require 'restore_agent/object/directory'
    require 'restore_agent/object/mysql_server'
    require 'restore_agent/object_db'

    attr_reader :root

    def initialize(server)
      @server = server
      @root = RestoreAgent::Object::Root.new
      @snapshots = {}
    end


    def list_objects(path)
      puts "query for path: #{path}"
      if o = @root.find_object(path)
        return o.list_objects
      end
      return []
    end
    
    def new_snapshot(id, objects)
      puts "new snapshot: #{id}"
      # XXX check for its existence
      @snapshots[id] = RestoreAgent::Handler::Snapshot.new(@server, id, objects)      
      @server.add_handler("snapshot.#{id}", @snapshots[id])
      return "OK"
    end

    # XXX only for testing
    def get_file(path)
      return File.new(path)
    end

  end

end