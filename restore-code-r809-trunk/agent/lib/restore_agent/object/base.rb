module RestoreAgent::Object
  
  module ContainerMixin
    require 'cgi'
    
    attr_accessor :children
        
    # given a path, return the object that matches by name
    # the path is relative to this object, so the first component
    # of it is supposed to match up with a child object
    def find_object(path)
      path_array = path.split(/\//)
      n = CGI::unescape(path_array.shift)
      #puts "looking for #{n} #{path} #{path_array.inspect}"
      
      children.each do |c|
        # look for an object with named by n
        if c.name == n
          return c if path_array.empty?
          return c.find_object(path_array.join('/'))
        end
      end
      return nil
    end
    
    def container?
      true
    end
    
    def list_objects
      return children.collect{|c| {:name => c.name, :type => c.type, :container => c.container?}}
    end
    
    def scan(snapper, included)
      puts "Scanning #{path} #{included}"
      
      modified = false

      # these hold attribute hashes for all objects under this one
      sub_objects = []

      # form an array of sub objects to scan.
      unless included
        # only log objects that are included
        puts "not included"
      else          
        # this objects is included, log all sub objects
        children.each do |c|
          #puts c.inspect
          #next if snapper.excluded?(c)          
          sub_objects << c
        end
        
      end
      
      sub_objects.each do |c|
        # scan the child
        modified = true if c.scan(snapper, included)
      end
      
      if modified
        puts "M #{self.path}"
        begin
          snapper.update_data(self.path, 'M', container?, {}, nil)
        rescue => e
          puts $!.to_s+e.backtrace.to_s
        end
        # update the db.
        #snapper.object_db[self.path] = {}
      end
      
      return modified
    end
  end
  
  class Base
    attr_reader :name
    attr_reader :parent
    attr_reader :type
    
    def initialize(parent, name)
      @parent, @name = parent, name
    end

    def container?
      false
    end
    
    def type
      self.class.to_s.split(/::/).last
    end
    
    def path
      p = CGI::escape(name)
      p = parent.path + "/" + p if parent
      p
    end
    
    def scan(snapper, included)
      puts "Scanning: #{path}"
      
      return false
    end
    
  end
end