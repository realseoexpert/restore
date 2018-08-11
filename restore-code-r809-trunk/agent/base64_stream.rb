
require 'lib/restore_agent'
require 'lib/restore_agent/xmlrpc/element'

require 'base64'
file = ARGV[0]

s = RestoreAgent::XMLRPC::Base64Stream.new(File.new(file))
File.open("/tmp/t1", "w") do |f|
  while data = s.read
    f.write data
    puts data.length
  end
end

File.open("/tmp/t2", "w") do |f|
  f.write Base64.decode64(File.read("/tmp/t1"))
end

system("md5sum #{file}")
system("md5sum /tmp/t2")
