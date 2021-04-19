if defined?(SSHKit)
  require_relative 'sshkit/backend/local'
  require_relative 'sshkit/host'
  SSHKit::Backend::Local.include GemExtensions::SSHKit::Backend::Local
  SSHKit::Host.include GemExtensions::SSHKit::Host
end
