require 'bdb43'
require 'fastthread'
require 'file_list'

def scan_directory(path)
  begin
    Dir.open(path) do |d|
      d.each do |f|
        f == '.' and next
        f == '..' and next

        file_path = File.join(path, f)
        event = nil

        st = File.lstat(file_path)
        unless file = @files[file_path]
          # file not in the db.  add it.
          file = {
            :mtime => st.mtime-1,
            :mode => st.mode
          }
          event = 'A'
        else
          # file was in the db before.  check mod time, etc
          event = 'M' if st.mtime > file[:mtime]
          event = 'M' if st.mode != file[:mode]
        end
        
        if event
          file[:mtime] = st.mtime
          puts "#{event} #{file_path}"
          @queue_semaphore.synchronize {
            @queue << {
              :path => file_path,
              :attrs =>  file
              }
          }
        end
        
        if !File.symlink?(file_path) && File.directory?(file_path)
          # directory
          modified = scan_directory(file_path)
        end
        
      end
    end
  rescue Errno::EACCES
    
  end
end

# BEGIN
@queue = []
@queue_semaphore = Mutex.new
@done = false

puts ARGV.inspect

@files = FileList.new(File.join(RESTORE_AGENT_ROOT, 'tmp', 'files.db')

t1 = Thread.new do
  scan_directory('/tmp')
  @done = true
end

t2 = Thread.new do
  loop do
    break if @done && @queue.size == 0
    begin
      file = nil
      @queue_semaphore.synchronize {
        file = @queue.shift
      }
      if file
        puts "Copying #{file[:path]}" if file
        #file[:attrs][:mtime] = Time.now
        @files[file[:path]] = file[:attrs]    
      end
    rescue => e
      puts e.inspect
    end
  end
end

t1.join
t2.join
