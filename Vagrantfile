# -*- mode: ruby -*-
# vi: set ft=ruby :

vm_spec = [
  { name:"vmbox",
    # Machine spec
    # ................
    cpu: 2,
    # memory MiB.
    memory: 4096,

    # Choice base box
    # ................
    box: "ubuntu/focal64",
    # box: "generic/ubuntu2004",
    # box: "bento/ubuntu-20.04",

    # ssh port forwarding spec[:ssh_port]->22.
    # ................
    # ssh_port: 22222,

    # ansible playbook
    # ................
    playbook: "playbook.yml",

    # if set vm_dir Change vdi image path.
    # ................
    # vm_dir: File.join("V:", "virtualbox"),

    # Description
    # ................
    comment: "Template VM"
  },
]

Vagrant.configure("2") do |config|
  vm_spec.each do |spec|
    config.vm.define spec[:name] do |vm|
      # box
      # ................................................................
      vm.vm.box = spec[:box]
      # Netowrk setting
      # ................................................................
      if !(spec[:ssh_port].nil?) then
        config.vm.network :forwarded_port, guest: 22, host: spec[:ssh_port]
      end

      # Setting virtualbox spec
      # ................................................................
      vm.vm.provider "virtualbox" do |vb|
        # Virtualbox setting
        vb.gui = false
        vb.cpus = spec[:cpu]
        vb.memory = spec[:memory]

        # Only run on the first build. Not run on reprovision or reload.
        if not File.exist?(
                 File.join(".vagrant","machines",spec[:name],"virtualbox","id")) then
          # Move VM dir.
          # ................................................................
          if !(spec[:vm_dir].nil?) then
            FileUtils.mkdir_p(spec[:vm_dir])
            vb.customize ['movevm', :id, '--folder', spec[:vm_dir]]
          end
        end
      end
      # Setting provision
      vm.vm.provision "ansible_local" do |an|
        an.limit = "all"
        an.playbook = File.join('playbook', spec[:playbook])
        an.inventory_path = "inventory"
        # an.verbose = true
      end
    end
  end
end
