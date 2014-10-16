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

require 'chef/platform/service_helpers'

class Chef
  class Platform
    class DefaultProviders
      class << self
        def provider_for(node, resource)
          case resource.resource_name
          when :service
            Chef::Platform::ServiceHelpers.provider_for(node)

          # the following is entirely static and should probably be moved into the resource
          when :bash
            Chef::Provider::Script
          when :csh
            Chef::Provider::Script
          when :directory
            Chef::Provider::Directory
          when :erl_call
            Chef::Provider::ErlCall
          when :execute
            Chef::Provider::Execute
          when :file
            Chef::Provider::File
          when :http_request
            Chef::Provider::HttpRequest
          when :link
            Chef::Provider::Link
          when :log
            Chef::Provider::Log::ChefLog
          when :perl
            Chef::Provider::Script
          when :python
            Chef::Provider::Script
          when :remote_directory
            Chef::Provider::RemoteDirectory
          when :route
            Chef::Provider::Route
          when :ruby
            Chef::Provider::Script
          when :ruby_block
            Chef::Provider::RubyBlock
          when :script
            Chef::Provider::Script
          when :template
            Chef::Provider::Template
          when :whyrun_safe_ruby_block
            Chef::Provider::WhyrunSafeRubyBlock
          else
            raise "something"
          end
        end
      end
    end
  end
end
