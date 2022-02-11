# frozen_string_literal: true

vm_specs = {
  vmbox: {
    # Base image.
    box: 'ubuntu/focal64',
    # box: 'generic/ubuntu2004',
    # box: 'bento/ubuntu-20.04',
    # Machine specs, The unit of 'memory' is MiB.
    cpu: 2, memory: 4096,
    # Port forawarding map. This hash key is host port and value is guest port.
    # portmap: {
    #   22_222 => 22,
    # },
    # Expand primary disk option. NOTE: Ignoring when reduced.
    # expand_primary: '64GB',
    # Changes virtualbox directory. NOTE: Only works at creating.
    # vm_dir: File.join('V:', 'virtualbox'),
    # ansible playbook
    playbook: 'playbook.yml',
  },
}

def provisioning(vmd, playbook)
  vmd.vm.provision 'ansible_local' do |an|
    an.limit = 'all'
    an.playbook = File.join('playbook', playbook)
    an.inventory_path = 'inventory'
    # an.verbose = true
  end
end

def oncreate?(name)
  vagrantdir = File.join('.vagrant', 'machines', name.to_s, 'virtualbox', 'box_meta')
  !File.exist?(vagrantdir)
end

def subcommand
  ARGV.each do |arg|
    return arg unless arg.start_with?('-')
  end
end

def install_plugin_ifneed(name)
  # When subcommand is `plugin expunge`, this function stack by a recursive call.
  # Therefore early return when subcommand is plugin.
  return if subcommand == 'plugin'
  # Early return when already installed the plugin.
  return if Vagrant.has_plugin?(name)

  system("vagrant plugin install --local #{name}")
  # Restart for the plugin features to take effect.
  exit system('vagrant', *ARGV)
end

Vagrant.configure('2') do |config|
  vm_specs.each do |name, spec|
    config.vm.define name do |vmd|
      # box
      # ................................................................
      vmd.vm.box = spec[:box]
      # Netowrk setting
      # ................................................................
      if spec.key?(:portmap)
        spec[:portmap].each do |from, to|
          config.vm.network :forwarded_port, guest: to, host: from
        end
      end

      # Expand primary disk.
      if spec.key?(:expand_primary)
        install_plugin_ifneed('vagrant-disksize')
        vmd.disksize.size = spec[:expand_primary]
      end

      # Specific virtualBox settings.
      vmd.vm.provider 'virtualbox' do |vb|
        # Virtualbox setting
        vb.gui = false
        vb.cpus = spec[:cpu]
        vb.memory = spec[:memory]

        # Move VM dir.
        # ................................................................
        if spec.key?(:vm_dir) && oncreate?(name)
          vb.customize ['movevm', :id, '--folder', spec[:vm_dir]]
        end
      end
      # Provisoning
      provisioning(vmd, spec[:playbook]) unless spec[:playbook].nil?
    end
  end
end
