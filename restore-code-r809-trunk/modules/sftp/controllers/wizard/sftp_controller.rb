# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
# Authors: Adam Lebsack <adam@holonyx.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

class Wizard::SftpController < Wizard::FilesystemController
  init_gettext "restore-module-sftp", :locale_path => File.join(RESTORE_ROOT, 'modules', 'sftp', 'locale')

  @@steps = [
  'server',
  'browse',
  'finalize']
  
  public
  def self.target_class
    Restore::Target::Sftp
  end


  def process_step_input(from, to)
    case steps[from]
    when 'server'
      @target.hostname = params[:target][:hostname]
      @target.port = params[:target][:port]
      @target.username = params[:target][:username]
      @target.password = params[:target][:password]
    when 'finalize'
    end
    super
  end
end
 