begin
  require "vagrant"
rescue LoadError
  raise "There was an error loading Vagrant"
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.2.0"
  raise "The Vagrant Force Rsync plugin is only compatible with Vagrant 1.2+"
end

module VagrantPlugins
  module ForceRsync

    VERSION = "0.0.1"

    class Plugin < Vagrant.plugin("2")
      name "ForceRsync"
      description <<-DESC
      The force rsync plugin allows a VM to use rsync as a provisioning step.
      DESC
      
      provisioner "force-rsync" do
        class ForceRsyncProvisioner < Vagrant.plugin("2", :provisioner)

          def initialize(machine, config)
            super
          end

          def configure(root_config)
          end

          def provision
            #options[:provision_ignore_sentinel] = false
            #@machine.action(:rsync, options)
            #puts exec('vagrant rsync')


            opts = {:hostpath=>'.', :guestpath=>'/vagrant/', :exclude=>'.git/', :args=> ["--verbose", "--archive", "-r", "-z", "--copy-links"]}

            ssh_info = machine.ssh_info

            # Folder info
            guestpath = opts[:guestpath]
            hostpath = opts[:hostpath]
            hostpath = File.expand_path(hostpath, machine.env.root_path)
            hostpath = Vagrant::Util::Platform.fs_real_path(hostpath).to_s
            if Vagrant::Util::Platform.windows?
              # rsync for Windows expects cygwin style paths, always.
              hostpath = Vagrant::Util::Platform.cygwin_path(hostpath)
            end
            # Make sure the host path ends with a "/" to avoid creating
            # a nested directory...
            if !hostpath.end_with?("/")
              hostpath += "/"
            end
            # Folder options
            opts[:owner] ||= ssh_info[:username]
            opts[:group] ||= ssh_info[:username]
            # Connection information
            username = ssh_info[:username]
            host = ssh_info[:host]
            proxy_command = ""
            if ssh_info[:proxy_command]
              proxy_command = "-o ProxyCommand='#{ssh_info[:proxy_command]}' "
            end
            rsh = [
                   "ssh -p #{ssh_info[:port]} " +
                   proxy_command +
                   "-o StrictHostKeyChecking=no " +
                   "-o UserKnownHostsFile=/dev/null",
                   ssh_info[:private_key_path].map { |p| "-i '#{p}'" },
                  ].flatten.join(" ")
            # Exclude some files by default, and any that might be configured
            # by the user.
            excludes = ['.vagrant/']
            excludes += Array(opts[:exclude]).map(&:to_s) if opts[:exclude]
            excludes.uniq!
            # Get the command-line arguments
            args = nil
            args = Array(opts[:args]).dup if opts[:args]
            args ||= ["--verbose", "--archive", "--delete", "-z", "--copy-links"]
            # On Windows, we have to set a default chmod flag to avoid permission issues
            if Vagrant::Util::Platform.windows? && !args.any? { |arg| arg.start_with?("--chmod=") }
              # Ensures that all non-masked bits get enabled
              args << "--chmod=ugo=rwX"
              # Remove the -p option if --archive is enabled (--archive equals -rlptgoD)
              # otherwise new files will not have the destination-default permissions
              args << "--no-perms" if args.include?("--archive") || args.include?("-a")
            end
            # Disable rsync's owner/group preservation (implied by --archive) unless
            # specifically requested, since we adjust owner/group to match shared
            # folder setting ourselves.
            args << "--no-owner" unless args.include?("--owner") || args.include?("-o")
            args << "--no-group" unless args.include?("--group") || args.include?("-g")
            # Tell local rsync how to invoke remote rsync with sudo
            if machine.guest.capability?(:rsync_command)
              args << "--rsync-path"<< machine.guest.capability(:rsync_command)
            end
            # Build up the actual command to execute
            command = [
                       "rsync",
                       args,
                       "-e", rsh,
                       excludes.map { |e| ["--exclude", e] },
                       hostpath,
                       "#{username}@#{host}:#{guestpath}",
                      ].flatten
            # The working directory should be the root path
            command_opts = {}
            command_opts[:workdir] = machine.env.root_path.to_s
            machine.ui.info(I18n.t(
                                   "vagrant.rsync_folder", guestpath: guestpath, hostpath: hostpath))
            if excludes.length > 1
              machine.ui.info(I18n.t(
                                     "vagrant.rsync_folder_excludes", excludes: excludes.inspect))
            end
            # If we have tasks to do before rsyncing, do those.
            if machine.guest.capability?(:rsync_pre)
              machine.guest.capability(:rsync_pre, opts)
            end
            r = Vagrant::Util::Subprocess.execute(*(command + [command_opts]))
            if r.exit_code != 0
              raise Vagrant::Errors::RSyncError,
              command: command.join(" "),
              guestpath: guestpath,
              hostpath: hostpath,
              stderr: r.stderr
            end
            # If we have tasks to do after rsyncing, do those.
            if machine.guest.capability?(:rsync_post)
              machine.guest.capability(:rsync_post, opts)
            end

          end

          def cleanup
          end

        end
        ForceRsyncProvisioner

      end
    end
  end
end

