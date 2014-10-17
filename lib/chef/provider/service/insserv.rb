#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/provider/service/init'
require 'chef/util/path_helper'

class Chef
  class Provider
    class Service
      class Insserv < Chef::Provider::Service::Init

        implements :service
        replaces Chef::Provider::Service::Init
        replaces Chef::Provider::Service::Debian
        replaces Chef::Provider::Service::Invokercd
        replaces Chef::Provider::Service::Redhat
        supports_os :linux

        def self.handles?(resource, action)
          Chef::Platform::ServiceHelpers.service_resource_providers.include?(:insserv)
        end

        def load_current_resource
          super

          # Look for a /etc/rc.*/SnnSERVICE link to signify that the service would be started in a runlevel
          if Dir.glob("/etc/rc**/S*#{Chef::Util::PathHelper.escape_glob(current_resource.service_name)}").empty?
            current_resource.enabled false
          else
            current_resource.enabled true
          end

          current_resource
        end

        def enable_service()
          shell_out!("/sbin/insserv -r -f #{new_resource.service_name}")
          shell_out!("/sbin/insserv -d -f #{new_resource.service_name}")
        end

        def disable_service()
          shell_out!("/sbin/insserv -r -f #{new_resource.service_name}")
        end
      end
    end
  end
end
