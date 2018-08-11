module RestoreAgent::Object
  class Directory < File
    include ContainerMixin

    def children
      # child method will load or refresh the child list
      @children ||= []
      newchildren = []
      #puts "listing in "+file_path.inspect
      
      begin
        Dir.open(file_path) do |d|
          d.each do |f|
            f == '.' and next
            f == '..' and next

            if obj = child_by_name(f)
              # found in old list.
              newchildren << obj
            else
              # new object
              path = ::File.join(file_path, f)
              if !::File.symlink?(path) && ::File.directory?(path)
                newchildren << Directory.new(self, f)            
              else
                newchildren << File.new(self, f)
              end
            end 
          end
        end
      rescue Errno::EACCES
        puts "permission denied"
        # log error for this object
      rescue => e
        puts e.to_s
      end
      @children = newchildren
    end
    
    def child_by_name(n)
      @children.each do |c|
        if c.name == n
          return c
        end
      end
      return nil
    end
    


  end  
end