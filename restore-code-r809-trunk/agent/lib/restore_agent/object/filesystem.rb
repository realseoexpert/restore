module RestoreAgent::Object
  class Filesystem < Base
    include ContainerMixin
    
    attr_reader :mount_point
    
    def initialize(parent, name, mount_point)
      name.gsub!(/^\/dev\//,'')
      super(parent, "[#{name}]")
      @mount_point = mount_point
    end
    
    def children
      @children = []
      Dir.open(@mount_point) do |d|
        d.each do |f|
          f == '.' and next
          f == '..' and next
          path = ::File.join(@mount_point, f)

          if !::File.symlink?(path) && ::File.directory?(path)
            @children << Directory.new(self, f)
          else
            @children << File.new(self, f)
          end
        end
      end
      @children
    end

    #def find_object(path)
    #  puts "looking for #{path}"
    #end

    

  end  
end