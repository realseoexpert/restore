module RestoreAgent::Object
  class File < Base
    
    def file_path
      if parent.type == 'Filesystem'
        ::File.join(parent.mount_point, name)
      else
        ::File.join(parent.file_path, name)
      end
    end
    
    def scan(snapper, included)
      event = nil
      
      st = ::File.lstat(self.file_path)
      unless attrs = snapper.object_db[self.path]
        # file not in the db.  add it.
        attrs = {
          :mtime => st.mtime,
          :mode => st.mode
        }
        event = 'A'
      else
        # file was in the db before.  check mod time, etc
        #if st.mtime > attrs[:mtime] || st.mode != attrs[:mode]
          attrs = {
            :mtime => st.mtime,
            :mode => st.mode
          }
          event = 'M'
        #end
      end
      
      if event
        puts "#{event} #{self.path}"
        
        # ask the snapper object to send the needed data back to the master.
        # all we need to provide is the event, our object path, and an IO object
        # to the data.
        begin
          f = ::File.new(self.file_path, "r")
        rescue => e
          puts e.to_s
        ensure
          begin
            snapper.update_data(self.path, event, container?, {}, f)
          rescue => e
            puts e.to_s
          ensure
            f.close if f
          end
        end
        #snapper.object_db[self.path] = attrs
        return true
      end
      return false      
    end
    
  end  
end