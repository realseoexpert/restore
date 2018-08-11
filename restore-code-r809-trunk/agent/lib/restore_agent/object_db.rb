module RestoreAgent
  class ObjectDB
    require 'bdb43'
    require 'thread'
    def initialize(path)
      @db = BDB::Hash.open(path, 'objects', BDB::CREATE)
      @sem = Mutex.new
    end

    def close
      @db.close
    end

    def [](path)
      val = nil
      @sem.synchronize {
        val =  @db[path]
      }
      return Marshal.load(val) if val
    end

    def []=(path, val)
      @sem.synchronize {
        @db[path] = Marshal.dump(val)
      }
    end  
  end
end
