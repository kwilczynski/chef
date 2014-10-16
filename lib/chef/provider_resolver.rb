#
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2014 Richard Manyanza.
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

require 'chef/exceptions'
require 'chef/platform/default_providers'

class Chef
  class ProviderResolver

    FORCE_DYNAMIC_RESOLUTION = [ :service, :file ]

    attr_reader :node

    def initialize(node)
      @node = node
    end

    # return a deterministically sorted list of Chef::Provider subclasses
    def providers
      Chef::Provider.descendants.sort {|a,b| a.to_s <=> b.to_s }
    end

    def resolve(resource, action)
      provider = maybe_explicit_provider(resource)

      if provider.nil?
        provider = maybe_dynamic_provider_resolution(resource, action)
      end

      if provider.nil?
        if must_dynamically_resolve(resource)
          provider = maybe_default_provider_helper(resource)
        else
          provider = maybe_chef_platform_lookup(resource, action)
        end
      end

      provider.action = action
      provider
    end

    private

    def must_dynamically_resolve(resource)
      FORCE_DYNAMIC_RESOLUTION.include?(resource.resource_name)
    end

    # if resource.provider is set, just return one of those objects
    def maybe_explicit_provider(resource)
      return nil unless resource.provider
      resource.provider.new(resource, resource.run_context)
    end

    def maybe_default_provider_helper(resource)
      Chef::Platform::DefaultProviders.provider_for(node, resource).new(resource, resource.run_context)
    end

    # try dynamically finding a provider based on querying the providers to see what they support
    def maybe_dynamic_provider_resolution(resource, action)
      handlers = providers.select do |klass|
        klass.enabled?(node) && klass.implements?(resource)
      end

      # log this so we know what providers will work for the generic resource on the node
      Chef::Log.debug "providers for generic #{resource.resource_name} resource enabled on node include: #{handlers}"

      handlers.select! do |klass|
        klass.handles?(resource, action)
      end

      # log this separately from above so we know what providers were excluded by config
      Chef::Log.debug "providers that support resource #{resource} include: #{handlers}"

      # classes can declare that they replace other classes, gather them all
      replacements = handlers.map { |klass| klass.replaces }.flatten

      # reject all the classes that have been replaced
      handlers -= replacements

      Chef::Log.debug "providers that survived replacement include: #{handlers}"

      raise Chef::Exceptions::AmbiguousProviderResolution.new(resource, handlers) if handlers.count >= 2

      return nil if handlers.empty?

      handlers[0].new(resource, resource.run_context)
    end

    # try the old static lookup of providers by platform
    def maybe_chef_platform_lookup(resource, action)
      Chef::Platform.provider_for_resource(resource, action)
    end
  end
end
