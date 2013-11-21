require 'spec_helper'

describe Aerosol::Deploy do
  let!(:ssh) { double(:ssh) }
  subject { described_class.new(:name => :test) }

  before do
    subject.stub(:ssh).and_return(ssh)
  end

  describe '#migration' do
    context 'by default' do
      its(:migrate?) { should be_true }
    end

    context 'when do_not_migrate! has been called' do
      before { subject.do_not_migrate! }

      its(:migrate?) { should be_false }
    end
  end

  describe '#run_post_deploy' do
    context 'with no post_deploy_command' do
      before do
        subject.stub(:post_deploy_command)
      end

      it "doesn't raises an error" do
        expect { subject.run_post_deploy }.to_not raise_error
      end

      it "returns nil" do
        expect(subject.run_post_deploy).to be_nil
      end
    end

    context 'with post_deploy_command' do
      context 'and post_deploy_command runs correctly' do
        before do
          subject.stub(:post_deploy_command).and_return('true')
        end

        it "doesn't raises an error" do
          expect { subject.run_post_deploy }.to_not raise_error
        end

        it "returns true" do
          expect(subject.run_post_deploy).to be_true
        end
      end

      context 'and post_deploy_command runs incorrectly' do
        before do
          subject.stub(:post_deploy_command).and_return('false')
        end

        it 'raises an error' do
          expect { subject.run_post_deploy }.to raise_error
        end
      end
    end
  end

  describe '#local_ssh_ref' do
    context 'when there is no local_ssh' do
      its(:local_ssh_ref) { should eq(ssh) }
    end

    context 'when there is a local_ssh' do
      let!(:local_ssh) { double(:local_ssh) }
      before do
        subject.stub(:local_ssh).and_return(local_ssh)
      end

      its(:local_ssh_ref) { should eq(local_ssh) }
    end
  end

  describe '#generate_ssh_command' do
    let(:ssh_ref) { double(:ssh_ref) }
    let(:instance) { double(:instance) }
    let(:ssh_command) { subject.generate_ssh_command(instance) }

    before do
      instance.stub(:public_hostname).and_return('hostname.com')
      subject.stub(:local_ssh_ref).and_return(ssh_ref)
    end

    context 'with a user' do
      before do
        ssh_ref.stub(:user).and_return('ubuntu')
      end

      context 'without a jump server' do
        before do
          ssh_ref.stub(:jump)
        end

        it 'responds with no jump server' do
          expect(ssh_command).to be =~ /ssh .* ubuntu@hostname.com/
        end
      end

      context 'with a jump server' do
        before do
          ssh_ref.stub(:jump).and_return(:user => 'candle', :host => 'example.org')
        end

        it 'responds with a jump server' do
          expect(ssh_command).to be =~ /ssh .* -o 'ProxyCommand=ssh -W %h:%p candle@example\.org' ubuntu@hostname\.com/
        end
      end
    end

    context 'without a user' do
      before do
        ssh_ref.stub(:user)
      end

      context 'without a jump server' do
        before do
          ssh_ref.stub(:jump)
        end

        it 'responds with no user and no jump' do
          expect(ssh_command).to be =~ /ssh .* hostname.com/
        end
      end

      context 'with a jump server' do
        before do
          ssh_ref.stub(:jump).and_return(:user => 'candle', :host => 'example.org')
        end

        it 'responds with no user and a jump server' do
          expect(ssh_command).to be =~ /ssh .* -o 'ProxyCommand=ssh -W %h:%p candle@example\.org' hostname\.com/
        end
      end
    end
  end
end
