# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "omalley/centos7_x64"
  config.vm.provision "shell", inline: <<-SHELL
    cp -r /vagrant/puppet/* /etc/puppetlabs/puppet
    cp /vagrant/run.sh /root
    chmod +x /root/run.sh
    cp /vagrant/manifest.pp /root
    cp /vagrant/event.json /root
  SHELL
end
