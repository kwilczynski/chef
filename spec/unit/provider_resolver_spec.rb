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

  # want a test double, but it needs state for the run_context
  class MyNode
    attr_accessor :run_context
  end

  let(:node) do
    node = MyNode.new
    allow(node).to receive(:[]).with(:os).and_return(os)
    allow(node).to receive(:[]).with(:platform_family).and_return(platform_family)
    allow(node).to receive(:[]).with(:platform).and_return(platform)
    allow(node).to receive(:[]).with(:platform_version).and_return(platform_version)
    node
  end

  let(:provider_resolver) { Chef::ProviderResolver.new(node) }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:resolved_provider) { provider_resolver.resolve(resource, action) }

  describe "resolving service resource" do
    def stub_service_providers(*services)
      services ||= []
      allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers)
        .and_return(services)
    end

    def stub_service_configs(*configs)
      configs ||= []
      allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
        .and_return(configs)
    end

    before do
      expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
    end

    let(:resource) { Chef::Resource::Service.new("ntp", run_context) }

    let(:action) { :start }

    shared_examples_for "a debian platform with upstart and update-rc.d" do
      before do
        stub_service_providers(:debian, :invokercd, :upstart)
      end

      it "when only the SysV init script exists, it returns a Service::Debian provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :initd ] )
        expect(resolved_provider).to be_a(Chef::Provider::Service::Debian)
      end

      it "when both SysV and Upstart scripts exist, it returns a Service::Upstart provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :initd, :upstart ] )
        expect(resolved_provider).to be_a(Chef::Provider::Service::Upstart)
      end

      it "when only the Upstart script exists, it returns a Service::Upstart provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :upstart ] )
        expect(resolved_provider).to be_a(Chef::Provider::Service::Upstart)
      end

      it "when both do not exist, it calls the old style provider resolver and returns a Debian Provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ ] )
        expect(resolved_provider).to be_a(Chef::Provider::Service::Debian)
      end
    end

    shared_examples_for "a debian platform using the insserv provider" do
      context "with a default install" do
        before do
          stub_service_providers(:debian, :invokercd, :insserv)
        end

        it "uses the Service::Insserv Provider to manage sysv init scripts" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :initd ] )
          expect(resolved_provider).to be_a(Chef::Provider::Service::Insserv)
        end
      end

      context "when the user has installed upstart" do
        before do
          stub_service_providers(:debian, :invokercd, :insserv, :upstart)
        end

        it "when only the SysV init script exists, it returns a Service::Debian provider" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :initd ] )
          expect(resolved_provider).to be_a(Chef::Provider::Service::Insserv)
        end

        it "when both SysV and Upstart scripts exist, it returns a Service::Upstart provider" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :initd, :upstart ] )
          expect(resolved_provider).to be_a(Chef::Provider::Service::Upstart)
        end

        it "when only the Upstart script exists, it returns a Service::Upstart provider" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :upstart ] )
          expect(resolved_provider).to be_a(Chef::Provider::Service::Upstart)
        end

        it "when both do not exist, it calls the old style provider resolver and returns a Debian Provider" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ ] )
          expect(resolved_provider).to be_a(Chef::Provider::Service::Insserv)
        end
      end
    end

    describe "on Linux" do
    end

    describe "on Ubuntu 14.04" do
      let(:os) { "linux" }
      let(:platform) { "ubuntu" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "14.04" }

      it_behaves_like "a debian platform with upstart and update-rc.d"
    end

    describe "on Ubuntu 10.04" do
      let(:os) { "linux" }
      let(:platform) { "ubuntu" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "10.04" }

      it_behaves_like "a debian platform with upstart and update-rc.d"
    end

    # old debian uses the Debian provider (does not have insserv or upstart, or update-rc.d???)
    describe "on Debian 4.0" do
      let(:os) { "linux" }
      let(:platform) { "debian" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "4.0" }

      #it_behaves_like "a debian platform using the debian provider"
    end

    # Debian replaced the debian provider with insserv in the FIXME:VERSION distro
    describe "on Debian 7.0" do
      let(:os) { "linux" }
      let(:platform) { "debian" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "7.0" }

      it_behaves_like "a debian platform using the insserv provider"
    end

    %w{solaris2 openindiana opensolaris nexentacore omnios smartos}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "solaris2" }
        let(:platform) { platform }
        let(:platform_family) { platform }
        let(:platform_version) { "5.11" }

        it "returns a Solaris provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to be_a(Chef::Provider::Service::Solaris)
        end

        it "always returns a Solaris provider" do
          # no matter what we stub on the next two lines we should get a Solaris provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Solaris)
        end
      end
    end

    %w{mswin mingw32 windows}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "windows" }
        let(:platform) { platform }
        let(:platform_family) { "windows" }
        let(:platform_version) { "5.11" }

        it "returns a Windows provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to be_a(Chef::Provider::Service::Windows)
        end

        it "always returns a Windows provider" do
          # no matter what we stub on the next two lines we should get a Windows provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Windows)
        end
      end
    end

    %w{mac_os_x mac_os_x_server}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "darwin" }
        let(:platform) { platform }
        let(:platform_family) { "mac_os_x" }
        let(:platform_version) { "10.9.2" }

        it "returns a Macosx provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to be_a(Chef::Provider::Service::Macosx)
        end

        it "always returns a Macosx provider" do
          # no matter what we stub on the next two lines we should get a Macosx provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Macosx)
        end
      end
    end

    %w{freebsd netbsd}.each do |platform|
      describe "on #{platform}" do
        let(:os) { platform }
        let(:platform) { platform }
        let(:platform_family) { platform }
        let(:platform_version) { "10.0-RELEASE" }

        it "returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          stub_service_providers
          stub_service_configs(:usr_local_etc_rcd)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Freebsd)
        end

        it "returns a Freebsd provider if it finds the /etc/rc.d initscript" do
          stub_service_providers
          stub_service_configs(:etc_rcd)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Freebsd)
        end

        it "always returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          # should only care about :usr_local_etc_rcd stub in the service configs
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:usr_local_etc_rcd, :initd, :upstart, :xinetd, :systemd)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Freebsd)
        end

        it "always returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          # should only care about :etc_rcd stub in the service configs
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:etc_rcd, :initd, :upstart, :xinetd, :systemd)
          expect(resolved_provider).to be_a(Chef::Provider::Service::Freebsd)
        end

        it "foo" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to be_a(Chef::Provider::Service::Freebsd)
        end
      end
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
