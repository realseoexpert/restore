module RestoreAgent::Object
  class Root < Base
    include ContainerMixin
    
    def initialize
      super(nil, 'root')
      @children = []
      
      # load mounts from the mount command
      IO.popen('mount') do |f|
        f.each do |l|
          if l =~ /(.+) on (.+) type (.+) \((.+)\)/
            what = $1
            where = $2
            type = $3
            args = $4
            next if pseudo_filesystems.include?(type)
            @children << Filesystem.new(self, what, where)
          end
        end
      end      
      @children << MysqlServer.new(self, 'Mysqld')
    
    end

    def pseudo_filesystems
      ['proc', 'binfmt_misc', 'nfsd', 'securityfs', 'devpts', 'sysfs']
    end

    def find_object(path)
      if path == '/'
        return self
      else

        super(path[1..-1])
      end
    end
    
    def path
      ''
    end


  end  
end