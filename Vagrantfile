# -*- mode: ruby -*-
# vi: set ft=ruby :
# -*- mode: ruby -*-
# vi: set ft=ruby :

IMAGE_NAME = ENV["IMAGE_NAME"] || "ubuntu/bionic64"
MASTER_MEMORY = ENV["MASTER_CPUS"] || 4096
MASTER_CPUS = ENV["MASTER_CPUS"] || 2
WORKER_CPUS = ENV["WORKER_CPUS"] || 2
BASE_IP = ENV["BASE_IP"] || "10.0.0"

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  

  config.vm.define "aqua" do |master|
      master.vm.provider "virtualbox" do |v|
          v.memory = MASTER_MEMORY
          v.cpus = MASTER_CPUS
      end
      
      master.vm.box = IMAGE_NAME
      master.vm.network "private_network", ip: "#{BASE_IP}.#{10}"
      master.vm.hostname = "aqua"
      
       

      master.vm.provision "shell" do |shell|
          shell.path = "aqua/script.sh"
      end 
      
      master.vm.synced_folder "aqua/", "/home/vagrant/aqua"
  end

  
  config.vm.define "jenkins" do |jenkins|
      jenkins.vm.provider "virtualbox" do |v|
          v.memory = 2600
          v.cpus = WORKER_CPUS 
      end
      
      jenkins.vm.hostname = "jenkins"
      jenkins.vm.box = IMAGE_NAME 
      jenkins.vm.network "private_network", ip: "10.0.0.25"
      jenkins.vm.network "forwarded_port", guest: 80, host: 8080
      
      
      jenkins.vm.provision "shell" do |shell|
          shell.path = "jenkins/jenkins.sh"
      end
  end     
     
end
