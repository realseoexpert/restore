class FileList
  def initialize(path)
    @files_db = BDB::Hash.open(path, 'files', BDB::CREATE)
    @sem = Mutex.new
  end
  
  def close
    @files_db.close
  end
  
  def [](path)
    val = nil
    @sem.synchronize {
      val =  @files_db[path]
    }
   return Marshal.load(val) if val
   
  end

  def []=(path, val)
    @sem.synchronize {
      @files_db[path] = Marshal.dump(val)
    }
  end  
end