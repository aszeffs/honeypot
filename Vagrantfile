Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "honeypot-lab"
  config.vm.network "private_network", ip: "192.168.56.10"
  config.ssh.host = "192.168.56.10"

  config.trigger.after :up do |trigger|
    trigger.info = "Disconnecting runtime connectivity..."
    trigger.run = {inline: "powershell.exe -ExecutionPolicy Bypass -File scripts/disconnect_runtime.ps1"}
  end

  config.vm.provider "virtualbox" do |vb|
    vb.name = "honeypot-lab"
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provision "shell", path: "scripts/provision.sh"
end
