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

require 'restore/installation/base'

class Restore::Installation::Enterprise < Restore::Installation::Base
    
  def targets
    Restore::Target::Base.find(:all)
  end
  
  def target_by_name(name)
    Restore::Target::Base.find_by_name(name)
  end

  def users
    Restore::Account::User.find(:all)
  end
  
  def find_user(id)
    Restore::Account::User.find(id)
  end
  
  def build_user(options={})
    Restore::Account::User.new(options)
  end

  def groups
    Restore::Account::Group.find(:all)
  end

  def find_group(id)
    Restore::Account::Group.find(id)
  end
  
  def build_group(options={})
    Restore::Account::Group.new(options)
  end


  def accounts
    users + groups
  end

  def size
    targets.inject(0) {|s,t| s += t.size rescue 0}
  end

  def quota
    Restore::Config.quota
  end
  
  def account(id)
    Restore::Account::User.find(id)
  end


end

class Object
  def dc_edition?
    false
  end  
  def e_edition?
    true
  end
end
