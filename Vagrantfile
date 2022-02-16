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
    # Private network (uses virtualbox internal network).
    private_ip: '172.16.20.11',
    public_ip: '192.168.11.101',
    # Expand primary disk option. NOTE: Ignoring when reduced.
    # expand_primary: '64GB',
    # Boot disks. (none, floppy, dvd, disk, net)
    # bootorder: %w[floppy dvd disk],
    # SerialPort Setting.
    # serial: {
    #   # 1 => { uart: ['0x3f8', 4], mode: %w[file NUL], type: ['16550A'] },
    #   # 2 => { uart: ['0x2f8', 3], mode: %w[file NUL], type: ['16550A'] },
    #   # 3 => { uart: ['0x3e8', 4], mode: %w[file NUL], type: ['16550A'] },
    #   # 4 => { uart: ['0x2e8', 3], mode: %w[file NUL], type: ['16550A'] },
    # },
    # Audio Setting
    # audio: { type: 'dsound', controller: 'ac97', codec: 'stac9700', in: 'off', out: 'off' },
    # Changes virtualbox directory. NOTE: Only works at creating.
    # vm_dir: File.join('V:', 'virtualbox'),
    # ansible playbook
    playbook: 'playbook.yml',
  },
}

def os
  @os ||= begin
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /mswin|msys|mingw|cyugwin|bccwin|wince|emc/ then :windows
    when /darwin|mac os/ then :macosx
    when /linux/ then :linux
    when /solaris|bsd/ then :unix
    else :unknown
    end
  end
end

def bridge_if_win
  desc = ''
  `ipconfig /all`.scan(/(Default.*|Description.*)/).each do |line|
    kv = line[0].split(' : ')
    case kv[0]
    when /^Description.*/ then desc = kv[1]
    when /^Default Gateway.*/
      return desc unless kv[1].nil?
    end
  end
end

def bridge_if_linux
  # Not tested
  `VBoxManage list bridgedifs | grep '^Name:' | head -n 1`.chomp.sub(
    /^Name: +/, '',
  )
end

def bridge_if
  @bridge_if ||=
    case os
    when :windows then bridge_if_win
    when :linux then bridge_if_linux
    end
end

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

# Abstrut configurator
class AbstructVboxConfigurator
  def initialize(vbox, spec_field, logger: nil)
    @vbox = vbox
    @spec = spec_field
    @logger = logger
  end

  def aply; end
end

# Virtualbox serial configurator.
class SerialConfigurator < AbstructVboxConfigurator
  def _apply_uart(port)
    cmd = ['modifyvm', :id, "--uart#{port}"]
    if @spec.nil? || !@spec.key?(port) || !@spec[port].key?(:uart)
      cmd.push('off')
    else
      cmd.push(@spec[port][:uart]).flatten!
    end
    @logger&.info "@@@@ #{cmd}"
    @vbox.customize cmd
  end

  def _aply_sub(port, symbol)
    if @spec.nil? || !@spec.key?(port) || !@spec[port].key?(:uart) || !@spec[port].key?(symbol)
      return
    end

    cmd = ['modifyvm', :id, "--uart#{symbol}#{port}", @spec[port][symbol]].flatten!
    @logger&.info "@@@@ #{cmd}"
    @vbox.customize cmd
  end

  def _apply_mode(port)
    _aply_sub(port, :mode)
  end

  def _apply_type(port)
    _aply_sub(port, :type)
  end

  def apply
    (1..4).each do |port|
      _apply_uart(port)
      _apply_mode(port)
      _apply_type(port)
    end
  end
end

# Virtualbox audio configurator
class AudioConfigurator < AbstructVboxConfigurator
  def _apply_type
    cmd = ['modifyvm', :id, '--audio']
    if @spec.nil? || !@spec.key?(:type)
      cmd.push('none')
    else
      cmd.push(@spec[:type])
    end
    @logger&.info "@@@@ #{cmd}"
    @vbox.customize cmd
  end

  def _apply(symbol)
    return if @spec.nil? || !@spec.key?(:type) || !@spec.key?(symbol)

    cmd = ['modifyvm', :id, "--audio#{symbol}", @spec[symbol]]
    @logger&.info "@@@@ #{cmd}"
    @vbox.customize cmd
  end

  def apply
    _apply_type
    _apply(:controller)
    _apply(:codec)
    _apply(:in)
    _apply(:out)
  end
end

# Virtualbox boot order configuration
class BootorderConfigurator < AbstructVboxConfigurator
  def _bootname(order)
    if @spec.nil?
      device = 'none'
      device = 'disk' if order.zero?
    else
      device = @spec[order].to_s
      device = 'none' if device == ''
    end
    device
  end

  def apply
    (0..3).each do |order|
      device = _bootname(order)
      cmd = ['modifyvm', :id, "--boot#{order + 1}", device]
      @logger&.info "@@@@ #{cmd}"
      @vbox.customize cmd
    end
  end
end

def configuration_network(vmd, spec)
  # Netowrk setting
  if spec.key?(:portmap)
    spec[:portmap].each do |from, to|
      vmd.vm.network :forwarded_port, guest: to, host: from
    end
  end
  # private_network
  vmd.vm.network :private_network, ip: spec[:private_ip] if spec.key?(:private_ip)
  # public netork
  vmd.vm.network :public_network, ip: spec[:public_ip], bridge: bridge_if if spec.key?(:public_ip)
end

Vagrant.configure('2') do |config|
  vm_specs.each do |name, spec|
    config.vm.define name do |vmd|
      # box
      vmd.vm.box = spec[:box]
      vmd.vm.hostname = name
      configuration_network(vmd, spec)
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
        if spec.key?(:vm_dir) && oncreate?(name)
          vb.customize ['movevm', :id, '--folder', spec[:vm_dir]]
        end
        # configure VM.
        BootorderConfigurator.new(vb, spec[:bootorder]).apply
        SerialConfigurator.new(vb, spec[:serial]).apply
        AudioConfigurator.new(vb, spec[:audio]).apply
      end
      # Provisoning
      provisioning(vmd, spec[:playbook]) unless spec[:playbook].nil?
    end
  end
end
