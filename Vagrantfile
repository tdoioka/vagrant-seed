# frozen_string_literal: true

vm_spec = [
  { name: 'vmbox',
    # Machine spec
    # ................
    cpu: 2,
    # memory MiB.
    memory: 4096,

    # Choice base box
    # ................
    box: 'ubuntu/focal64',
    # box: "generic/ubuntu2004",
    # box: "bento/ubuntu-20.04",

    # ssh port forwarding spec[:ssh_port]->22.
    # ................
    # ssh_port: 22222,

    # ansible playbook
    # ................
    playbook: 'playbook.yml',

    # if set vm_dir Change vdi image path.
    # ................
    # vm_dir: File.join('V:', 'virtualbox'),

    # Description
    # ................
    comment: 'Template VM' }
]

def provisioning(vmd, playbook)
  vmd.vm.provision 'ansible_local' do |an|
    an.limit = 'all'
    an.playbook = File.join('playbook', playbook)
    an.inventory_path = 'inventory'
    # an.verbose = true
  end
end

Vagrant.configure('2') do |config|
  vm_spec.each do |spec|
    config.vm.define spec[:name] do |vm|
      # box
      # ................................................................
      vm.vm.box = spec[:box]
      # Netowrk setting
      # ................................................................
      unless spec[:ssh_port].nil?
        config.vm.network :forwarded_port, guest: 22,
                                           host: spec[:ssh_port]
      end

      # Setting virtualbox spec
      # ................................................................
      vm.vm.provider 'virtualbox' do |vb|
        # Virtualbox setting
        vb.gui = false
        vb.cpus = spec[:cpu]
        vb.memory = spec[:memory]

        # Move VM dir.
        # ................................................................
        unless spec[:vm_dir].nil?
          # Move twice to supress the error at reload.
          vmdir = spec[:vm_dir]
          vmtmp = File.join(vmdir, 'tmp')
          # Create dir
          FileUtils.mkdir_p(vmtmp)
          vb.customize ['movevm', :id, '--folder', vmtmp]
          vb.customize ['movevm', :id, '--folder', vmdir]
        end
      end
      # Provisoning
      provisioning(vm, spec[:playbook]) unless spec[:playbook].nil?
    end
  end
end
