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

class Chef
  class ProviderResolver

    attr_reader :node

    def initialize(node)
      @node = node
    end

    # return a deterministically sorted list of Chef::Provider subclasses
    def each_provider
      ObjectSpace.each_object(Class).sort {|a,b| a.to_s <=> b.to_s }.each do |klass|
        yield klass if klass < Chef::Provider
      end
    end

    def resolve(resource, action)
      provider = maybe_explicit_provider(resource, action) ||
        maybe_dynamic_provider_resolution(resource, action) ||
        maybe_chef_platform_lookup(resource, action)
      provider.action = action
      provider
    end

    # if resource.provider is set, just return one of those objects
    def maybe_explicit_provider(resource, action)
      if resource.provider
        resource.provider.new(resource, resource.run_context)
      else
        nil
      end
    end

    # try dynamically finding a provider based on querying the providers to see what they support
    def maybe_dynamic_provider_resolution(resource, action)
      each_provider do |klass|
        if klass.enabled?(node) && klass.implements?(resource) && klass.handles?(resource, action)
          # Question: if we find more than one we just return the first, should we demand uniqueness
          # and throw an error instead?
          return klass.new(resource, resource.run_context)
        end
      end
      nil
    end

    # try the old static lookup of providers by platform
    def maybe_chef_platform_lookup(resource, action)
      Chef::Platform.provider_for_resource(resource, action)
    end
  end
end

