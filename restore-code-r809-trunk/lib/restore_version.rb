begin
  info = `readlink -f #{RESTORE_ROOT} | svn info`
  info.scan(/Last Changed Rev: (\d+)/)

  version = $1 if $1
  info.scan(/Last Changed Date: (\d+-\d+-\d+ \d+:\d+)/)
  date = $1 if $1
  
  RESTORE_VERSION="svn r#{version} (#{date})"
rescue
  RESTORE_VERSION='development'
end

