ethereum-environments
=====================

This projects provides the environments that allows you to create virtual machines (both remote and local) that run the various kinds of ethereum clients. Basically it allows you to build a full ethereum node with one command. 

The two node types currently supported are the cpp and go implementations of the ethereum non-gui client. These are installed from HEAD on the master branch and run as init.d system services with configurable parameters.

Support for other branches is coming. 

## Features
- apt management with unattended security updates 
- time server 
- users (ubuntu admin and ethereum)
- ethereum full node cli built from head
- ethereum launched as init.d system service running as ethereum user 
- ssh setup only public key connection (authorized keys setup)
- ufw firewall only open ethereum port and ssh
- fail2ban against ssh ddos

## Disclaimer

The ethereum project is in inception phase. All software and tools being developed are alpha. Adjust your expectations.

## TL;DR

### remote vm:

cpp:

    packer build -var-file=packer/nodes/cpp-ethereum.json packer/aws-template.json
    vagrant box add cpp-ethereum boxes/cpp-ethereum.aws.box
    ROLES=cpp-ethereum vagrant up aws-cpp-ethereum --provider=aws    

go:

    packer build -var-file=packer/nodes/go-ethereum.json packer/aws-template.json
    vagrant box add go-ethereum boxes/go-ethereum.aws.box
    ROLES=go-ethereum vagrant up aws-go-ethereum --provider=aws    

### local vm:

cpp:

    ROLES=cpp-ethereum vagrant up virtualbox-cpp-ethereum

go:

    ROLES=go-ethereum vagrant up virtualbox-go-ethereum

## Prerequisites

* packer - http://www.packer.io for remote 
* virtualbox - for local 
* vagrant - http://www.vagrantup.com/ for local and remote 
* vagrant plugins recommended: aws, vbguest

Tested on OSX with Packer v0.5.2, Vagrant 1.5.1, vagrant-aws (0.4.1), virtualbox 4.3.8 (4.3.10 buggy on OSX), vagrant-vbguest (0.10.0)

### Linux

Packer is distributed as a binary package and i know of no way to install it with a package manager. 

On deb style systems, vagrant installs simply with:

    sudo apt-get -y install vagrant

### on Mac OS X

There are various ways to install packer and vagrant. Here is a pure command line version using homebrew and cask.

    brew tap homebrew/binary
    brew install packer
    brew tap phinze/cask
    brew install brew-cask
    brew cask install vagrant

### vagrant plugins 

The `vbguest` plugin is useful to keep your guest editions uptodate (with virtualbox version). Version mismatch can often result in nasty errors.

    vagrant plugin install vagrant-vbguest

if you use this plugin, `vagrant up` will not be able to download the basebox, so you need to add it manually

    vagrant box add --name ubuntu14.04 --provider virtualbox http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box

vagrant-aws is used to manage remote aws vm-s with vagrant.
    
    vagrant plugin install vagrant-aws

## base OS for VMs

The base OS used for VMs here is cutting edge Ubuntu 14.04 (trusty):

- AWS EC2 eu-west-1 region ami: ami-335da344
- vagrant box: http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box

Note if you change to an older base OS, you need to make sure puppet 3.x is installed on the VM (not locally). For instance, ubuntu precise has puppet 2.7.x which is too old; to upgrade to puppet 3.x follow http://docs.puppetlabs.com/guides/puppetlabs_package_repositories.html#for-debian-and-ubuntu:

    wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
    sudo dpkg -i puppetlabs-release-precise.deb
    sudo apt-get update
    sudo apt-get install puppet

to automate this step you can add the lines to the shell provisioning section in `packer/aws-template.json`:

## local VM

The multi-machine `Vagrantfile` includes a section for local vms using virtualbox as provider. So you can use it to boot up temporary local instances for any node locally. This requires virtualbox to be installed on your host. 

    ROLES=go-ethereum vagrant up virtualbox-go-ethereum

## remote VM

You can create remote vms on amazon ec2 (called ami-s). This requires packer installed as well as having an amazon aws account. The setup is detailed below.

### aws ec2 setup

Assuming you are set up on amazon, go to console > 
account > security credentials https://console.aws.amazon.com/iam/home?#security_credential
and export your credentials (AWSAccessKeyId, AWSSecretKey) in `rootkey.cvs`

    AWSAccessKeyId=XXXXXXXXXXXXXXX
    AWSSecretKey=XXXXXXXXXXXXXX

To enable network access to your instances, you must allow inbound traffic to your instance. Create a security group within ec2 and add an inbound rule allowing all TCP traffic from anywhere. This sounds dangerous but we provision the server with firewall.
https://console.aws.amazon.com/ec2/home?region=us-east-1#s=SecurityGroups
Remember your security group name and id (this will be environment vars `AWS_SECURITY_GROUP` and `AWS_SECURITY_GROUP_ID`).

You should also create a named keypair and export its key into a `.pem` file. The path to this file should be `AWS_PRIVATE_KEY_FILE` and the name is `AWS_KEYPAIR_NAME`.

All credentials and other ec2 related variables are set via user variables http://www.packer.io/docs/templates/user-variables.html reading environment variables. E.g., `packer/aws-template.json`

    "variables": {
        "aws_access_key": "{{env `AWSAccessKeyId`}}",
        "aws_secret_key": "{{env `AWSSecretKey`}}"
    },

So create a file (say `aws.env`) setting environment variables (never share or commit this, as a precaution I added this to .gitignore): 

    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_KEY=
    export AWS_PRIVATE_KEY_FILE=
    export AWS_KEYPAIR_NAME=
    export AWS_SECURITY_GROUP=
    export AWS_SECURITY_GROUP_ID=

You need to source this file in your shell terminal.

    source ./aws.env

### setting ssh access via authorized_keys

Create a file `puppet/modules/users/files/.ssh/authorized_keys` within your working copy. Put your favourite public keys in there to grant access to the VM for both VM users: `ethereum` and `ubuntu` (admin). This file should *not* be under source control to avoid leaking email address etc. (as a precaution it is added to `.gitignore`). The format of the file is your usual `~/.ssh/authorized_keys`, simply one public key per line.
Note that we do not allow unsafe access to the remote vm by vagrant instead force it to connect as `ubuntu` user and your aws private key. This means you must add at least your aws public key to this file, otherwise `vagrant ssh` will be denied access after provisioning. 

Note that ssh access to your remote VM is also controlled by your instance's security group. If you explicitly whitelisted IP addresses, access will be limited to connections coming from those.

### building remote VMs on aws ec2

`packer/aws-template.json` is the template to create amazon machine instances (ami-s). For each node, there is a var file in `packer/nodes`. So to build an ec2 ami for say `go-ethereum` node: 

    source ./aws.env
    packer build -var-file=packer/nodes/go-ethereum.json packer/aws-template.json

VMs are available for the following nodes:

* cpp-ethereum (ethereum full node client cpp implementation built from head of master branch)
* go-ethereum (ethereum full node client go implementation built from head of master branch)

user variables overwritten in `packer/nodes/<NODENAME>.json`
- `nodename`: should match a top-level manifest basename with node def
- `source_ami`: base ami (eu-west1 ubuntu trusty)
- `instance_type`: aws instance type

Once the ami is created, you can make it public, see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/sharingamis-intro.html
If you play around and create ami-s you no longer want, make sure that you deregister them on the ec2 console or amazon will charge you (a minuscule fee) for storing them.

### bringing up VMs with vagrant 

After packer builds the ami, it also exports a corresponding aws vagrant box (using the vagrant postprocessor http://www.packer.io/intro/getting-started/vagrant.html. The box is saved under `boxes/<NODENAME>.aws.box`. This box contains the actual ami number so you do not need to set it.

To use this box, you need to install the `vagrant-aws` plugin for vagrant https://github.com/mitchellh/vagrant-aws, simply with

    vagrant plugin install vagrant-aws

Once you got the ami built with packer, you add the box:

    vagrant box add go-ethereum boxes/go-ethereum.aws.box

Now you can use the provided multi-machine `Vagrantfile` to boot up temporary instances for any node. (Note the extra `--provider=aws`):

    ROLES=go-ethereum vagrant up aws-go-ethereum --provider=aws

You can ssh into your remote instance (if you added your aws public key to the ssh authorized key file):

    ROLES=go-ethereum vagrant ssh aws-go-ethereum

or you can reprovision your instance using:

    ROLES=go-ethereum vagrant provision aws-go-ethereum 

This is set up to use the exact same puppet masterless process as packer. Remote provisioning with vagrant is only useful if you develop this project and want to test modifications in provisioning without recreating an instance with packer. It is also useful if packer provisioning fails. In this case, just delete the puppet section from the aws packer template, create the instance and then try provisioning with vagrant which you can debug properly by ssh-ing into the vm.

If you do `vagrant destroy`, the instance will indeed be terminated (in aws lingo):

    ROLES=go-ethereum vagrant destroy aws-go-ethereum

If you recreate an instance with packer, you need to remove and add the box again to vagrant.

## Hiera

I use hiera as parameter abstraction layer. A bit overkill at this stage but nice to document options.
Hiera calls in puppet should not use defaults, better style documenting all hiera variables by giving the default in `puppet/hiera/common.yaml`

## Developer notes

Compiling on the VM is a bit of a hack since it merges two distinct steps.
The ideal scenario is that we have a continuous release setup that creates unstable or head binary packages using development/compiler baseboxes. Node VMs on the other hand would then be created using these packages, ie., the relevant puppet modules would just install from a repo using a node basebox. 
This setup cuts across these two problems and implements it in one step until a binary repo with automated dev builds is available.
An additional benefit is that now developers can use the exact same environment to compile and test using vagrant on their private or remote aws instances. 

### Vision of a third layer for network testing 

Once the node VMs are created, their clones can be launched with automated scripts resulting in ethereum testnets composed of nodes with uniform and mixed implementations. 
These isolated testnets could then be used for integration testing and benchmarking: in one test round consisting of X blocks a suite of precanned transactions and contracts would be fired at the testnet and checked for correctness of operation as well as for expected measures on various network and mining statistics.

## Troubleshooting

### memory
cpp-ethereum compilation needs a lot of memory. If you get a mysterious `c++: internal compiler error: Killed (program cc1plus)` error, try increase your VM-s memory. In Vagrant, a generous 2GB is requested since the default 512MB is not enough. For aws m1.small instance type was chosen since m1.micro don't cut it.

### 
packer fails with `Build 'amazon-ebs' errored: extra data in buffer` or `Build 'amazon-ebs' errored: gob: decoding array or slice: length exceeds input size`,just run it again. 

## Credits
* https://github.com/zelig
* https://github.com/valzav
* https://github.com/caktux

## TODO
* solve logging to file on both clients
* support builds from other branches (needs more trix for go client)
* nodes running multiple clients
* add peer server nodes or components
* sort out miners address/key export and import 
* add packer template to support other cloud providers

##Contribute

Please contribute with pull requests.
