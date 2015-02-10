# Vagrant Force Rsync Provisioner

This is a Vagrant plugin that adds a `force-rsync` provisioning step that can
be used to force directory synchronization on a VM during provisioning.

# Installation

`$ vagrant plugin install vagrant-force-rsync`

## Usage

Add `config.vm.provision :force-rsync` to your `Vagrantfile` to rsync your VM
during provisioning.

## Development

To work on the `vagrant-force-rsync` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

    $ bundle

You can test the plugin without installing it into your Vagrant environment by 
just creating a `Vagrantfile` in the top level of this directory 
(it is gitignored) and add the following line to your `Vagrantfile` 

```ruby
Vagrant.require_plugin "vagrant-force-rsync"
```
Use bundler to execute Vagrant:

    $ bundle exec vagrant up

## Contributing

1. Fork it
2. Create your feature branch (`$ git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
