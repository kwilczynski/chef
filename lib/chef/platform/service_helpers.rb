#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

class Chef
  class Platform
    class ServiceHelpers
      class << self

        # This helper is mostly used to sort out the mess of different
        # linux mechanisms that can be used to start services.  It does
        # not necessarily need to linux-specific, but currently all our
        # other service providers are narrowly platform-specific with no
        # alternatives.
        def service_resource_providers
          service_resource_providers = []

          if ::File.exist?("/usr/sbin/update-rc.d")
            service_resource_providers << :debian
          end

          if ::File.exist?("/usr/sbin/invoke-rc.d")
            service_resource_providers << :invokercd
          end

          if ::File.exist?("/sbin/insserv")
            service_resource_providers << :insserv
          end

          # debian >= 6.0 has /etc/init but does not have upstart
          if ::File.exist?("/etc/init") && ::File.exist?("/sbin/start")
            service_resource_providers << :upstart
          end

          if ::File.exist?("/sbin/chkconfig")
            service_resource_providers << :redhat
          end

          if ::File.exist?("/bin/systemctl")
            # FIXME: look for systemd as init provider
            service_resource_providers << :systemd
          end

          service_resource_providers
        end

        def config_for_service(service_name)
          config = []

          if ::File.exist?("/etc/init.d/#{service_name}")
            configs << :initd
          end

          if ::File.exist?("/etc/init/#{service_name}.conf")
            configs << :upstart
          end

          if ::File.exist?("/etc/xinetd.d/#{service_name}")
            configs << :xinetd
          end

          if ::File.exist?("/etc/rc.d/#{service_name}")
            configs << :etc_rcd
          end

          if ::File.exist?("/usr/local/etc/rc.d/#{service_name}")
            configs << :usr_local_etc_rcd
          end

          if platform_has_systemd_unit?(service_name)
            configs << :systemd
          end

          configs
        end

        # This mapping is *ONLY* for the default provider if the provider
        # resolver dynamic resolution fails, and we have to return some kind of
        # best-guess provider for why-run and error messages.
        def provider_for(node)
          case node[:os]
          when "freebsd", "netbsd"
            Chef::Provider::Service::Freebsd
          when "mac_os_x"
            Chef::Provider::Service::Freebsd
          when "windows"
            Chef::Provider::Service::Windows
          when "solaris2"
            Chef::Provider::Service::Solaris2
          when "linux"
            Chef::Provider::Service::Init
          else
            Chef::Provider::Service::Init
          end
        end

        private

        def extract_systemd_services(output)
          # first line finds e.g. "sshd.service"
          services = output.lines.split.map { |l| l.split[0] }
          # this splits off the suffix after the last dot to return "sshd"
          services += services.map { |s| s.sub(/(.*)\..*/, '\1') }
        end

        def platform_has_systemd_unit?(service_name)
          services = extract_systemd_services(shell_out!("systemctl --all").stdout) +
            extract_systemd_services(shell_out!("systemctl --list-unit-files").stdout)
          services.include?(service_name)
        end
      end
    end
  end
end
