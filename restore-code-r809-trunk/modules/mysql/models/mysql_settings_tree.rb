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

module MysqlSettingsTree
  require_dependency 'mysql_settings_tree/server'
  require_dependency 'mysql_settings_tree/database'
  require_dependency 'mysql_settings_tree/table'
  require_dependency 'mysql_settings_tree/view'
  require_dependency 'mysql_settings_tree/routine'
end