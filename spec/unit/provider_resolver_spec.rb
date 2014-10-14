#
# Author:: Lamont Granquist (<lamont@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'spec_helper'

describe Chef::ProviderResolver do

  let(:node) do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = platform
    node.automatic_attrs[:platform_family] = platform_family
    node.automatic_attrs[:platform_version] = platform_version
    node
  end

  let(:provider_resolver) { Chef::ProviderResolver.new(node) }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:resolved_provider) { provider_resolver.resolve(resource, action) }

  describe "resolving service resource" do
    before do
      expect(File).not_to receive(:exist?)
      expect(File).not_to receive(:exists?)
    end

    let(:resource) { Chef::Resource::Service.new("ntp", run_context) }

    let(:action) { :start }

    shared_examples_for "a debian platform with upstart and update-rc.d" do
      before do
        expect(Chef::Provider).to receive(:platform_has_update_rcd?).at_least(:once).and_return(true)
        expect(Chef::Provider).to receive(:platform_has_insserv?).at_least(:once).and_return(false)
        expect(Chef::Provider).to receive(:platform_has_upstart?).at_least(:once).and_return(true)
      end

      it "when only the SysV init script exists, it returns a Service::Debian provider" do
        expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(true)
        expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(false)
        expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
        expect(resolved_provider).to be_a(Chef::Provider::Service::Debian)
      end

      it "when both SysV and Upstart scripts exist, it returns a Service::Upstart provider" do
        expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(true)
        expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(true)
        expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
        expect(resolved_provider).to be_a(Chef::Provider::Service::Upstart)
      end

      it "when only the Upstart script exists, it returns a Service::Upstart provider" do
        expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(false)
        expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(true)
        expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
        expect(resolved_provider).to be_a(Chef::Provider::Service::Upstart)
      end

      it "when both do not exist, it calls the old style provider resolver and returns a Debian Provider" do
        expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(false)
        expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(false)
        expect(provider_resolver).to receive(:maybe_chef_platform_lookup).with(resource, action).and_call_original
        expect(resolved_provider).to be_a(Chef::Provider::Service::Debian)
      end
    end

    shared_examples_for "a debian platform using the insserv provider" do
      context "with a default install" do
        before do
          expect(Chef::Provider).to receive(:platform_has_update_rcd?).at_least(:once).and_return(true)
          expect(Chef::Provider).to receive(:platform_has_insserv?).at_least(:once).and_return(true)
          expect(Chef::Provider).to receive(:platform_has_upstart?).at_least(:once).and_return(false)
        end

        it "uses the Service::Insserv Provider to manage sysv init scripts" do
          expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(true)
          expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(false)
          expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Insserv)
        end
      end

      context "when the user has installed upstart" do
        before do
          expect(Chef::Provider).to receive(:platform_has_update_rcd?).at_least(:once).and_return(true)
          expect(Chef::Provider).to receive(:platform_has_insserv?).at_least(:once).and_return(true)
          expect(Chef::Provider).to receive(:platform_has_upstart?).at_least(:once).and_return(true)
        end

        it "when only the SysV init script exists, it returns a Service::Debian provider" do
          expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(true)
          expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(false)
          expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Insserv)
        end

        it "when both SysV and Upstart scripts exist, it returns a Service::Upstart provider" do
          expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(true)
          expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(true)
          expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Upstart)
        end

        it "when only the Upstart script exists, it returns a Service::Upstart provider" do
          expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(false)
          expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(true)
          expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Upstart)
        end

        it "when both do not exist, it calls the old style provider resolver and returns a Debian Provider" do
          expect(Chef::Provider).to receive(:platform_has_initd_script?).at_least(:once).with("ntp").and_return(false)
          expect(Chef::Provider).to receive(:platform_has_upstart_script?).at_least(:once).with("ntp").and_return(false)
          expect(provider_resolver).to receive(:maybe_chef_platform_lookup).with(resource, action).and_call_original
          expect(resolved_provider).to be_a(Chef::Provider::Service::Insserv)
        end
      end
    end

    describe "on Ubuntu 14.04" do
      let(:platform) { "ubuntu" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "14.04" }

      it_behaves_like "a debian platform with upstart and update-rc.d"
    end

    describe "on Ubuntu 10.04" do
      let(:platform) { "ubuntu" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "10.04" }

      it_behaves_like "a debian platform with upstart and update-rc.d"
    end

    # old debian uses the Debian provider (does not have insserv or upstart, or update-rc.d???)
    describe "on Debian 4.0" do
      let(:platform) { "debian" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "4.0" }

      #it_behaves_like "a debian platform using the debian provider"
    end

    # Debian replaced the debian provider with insserv in the FIXME:VERSION distro
    describe "on Debian 7.0" do
      let(:platform) { "debian" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "7.0" }

      it_behaves_like "a debian platform using the insserv provider"
    end
  end
end

#            :ubuntu   => {
#                :service => Chef::Provider::Service::Debian,
#            :debian => {
#              :default => {
#                :service => Chef::Provider::Service::Debian,
#              ">= 6.0" => {
#                :service => Chef::Provider::Service::Insserv
#            :mac_os_x => {
#                :service => Chef::Provider::Service::Macosx,
#            :freebsd => {
#                :service => Chef::Provider::Service::Freebsd,
#            :centos   => {
#                :service => Chef::Provider::Service::Redhat,
#            :amazon   => {
#                :service => Chef::Provider::Service::Redhat,
#            :scientific => {
#                :service => Chef::Provider::Service::Redhat,
#            :fedora   => {
#                :service => Chef::Provider::Service::Redhat,
#            :opensuse     => {
#                :service => Chef::Provider::Service::Redhat,
#            :suse     => {
#                :service => Chef::Provider::Service::Redhat,
#            :oracle  => {
#                :service => Chef::Provider::Service::Redhat,
#            :redhat   => {
#                :service => Chef::Provider::Service::Redhat,
#            :gentoo   => {
#                :service => Chef::Provider::Service::Gentoo,
#            :arch   => {
#                :service => Chef::Provider::Service::Systemd,
#            :mswin => {
#                :service => Chef::Provider::Service::Windows,
#            :mingw32 => {
#                :service => Chef::Provider::Service::Windows,
#            :windows => {
#                :service => Chef::Provider::Service::Windows,
#            :openindiana => {
#                :service => Chef::Provider::Service::Solaris,
#            :opensolaris => {
#                :service => Chef::Provider::Service::Solaris,
#            :nexentacore => {
#                :service => Chef::Provider::Service::Solaris,
#            :omnios => {
#                :service => Chef::Provider::Service::Solaris,
#            :solaris2 => {
#                :service => Chef::Provider::Service::Solaris,
#            :smartos => {
#                :service => Chef::Provider::Service::Solaris,
#            :netbsd => {
#                :service => Chef::Provider::Service::Freebsd,
#            :openbsd => {
#                  ???
#            :hpux => {
#                  ???
#            :aix => {
#                  ???
#            :default => {
#              :service => Chef::Provider::Service::Init,
