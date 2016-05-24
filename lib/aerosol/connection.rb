require 'net/ssh'
require 'net/ssh/gateway'

class Aerosol::Connection
  include Dockly::Util::DSL
  include Dockly::Util::Logger::Mixin

  logger_prefix '[aerosol connection]'
  dsl_attribute :user, :host, :jump

  def with_connection(overridden_host=nil, &block)
    actual_host = overridden_host || host
    unless actual_host.is_a?(String)
      actual_host = actual_host.address
    end

    if jump
      info "connecting to gateway #{jump[:user] || user}@#{jump[:host]}"
      gateway = Net::SSH::Gateway.new(jump[:host], jump[:user] || user, :forward_agent => true, :timeout => 20)

      begin
        info "connecting to #{user}@#{actual_host} through gateway"
        gateway.ssh(actual_host, user, :timeout => 20, &block)
      ensure
        info "shutting down gateway connection"
        gateway.shutdown!
      end
    else
      info "connecting to #{user}@#{actual_host}"
      Net::SSH.start(actual_host, user, :timeout => 20, &block)
    end
  rescue Timeout::Error => ex
    error "Timeout error #{ex.message}"
    error ex.backtrace.join("\n")
  end
end
