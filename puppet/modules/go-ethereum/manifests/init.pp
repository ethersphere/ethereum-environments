class go-ethereum {

  include golang
  include ufw

  # package dependencies

  # this is the same as include but allows parameters
  # if specific version of go needed:
  # class { 'golang':
  #   version =>  '2:1.2.1-2ubuntu1'
  # }

  # $ppa='ppa:ubuntu-sdk-team/ppa'

  # apt::ppa { $ppa }

  $deps = [
      'libgmp3-dev',
      'pkg-config',
      'mercurial',
      'libleveldb1',
      'libreadline6-dev'
      ]

  # $gui_deps = [
  #     'ubuntu-sdk',
  #     'qtbase5-private-dev',
  #     'qtdeclarative5-private-dev',
  #     'libqt5opengl5-dev'
  #     ]

  package { [$deps]:
    ensure => present,
  }

  # package { [$gui_deps]:
  #   ensure => present,
  #   require => Apt::Ppa[$ppa]
  # }

  # compile from source
  $source = 'github.com/ethereum/go-ethereum/ethereum'
  $daemon_path = hiera('go-ethereum::cli_path')

  # note this installs the master branch
  # I have no idea how go can get away without version management - it's a mystery
  golang::install { "go-ethereum":
    source => $source,
    binary => "ethereum",
    destination => $daemon_path,
    require => Package[$deps]
  }

  # config variables for go-ethereum upstart service conf file
  $log_file = hiera('go-ethereum::log_file')
  $data_dir = hiera('go-ethereum::data_dir')
  $outbound_port = hiera('go-ethereum::outbound_port')
  $inbound_port = hiera('go-ethereum::inbound_port') # only used to open port
  $max_peer = hiera('go-ethereum::max_peer')

  file { "/etc/init/go-ethereum.conf":
    ensure    => "file",
    content   => template("${module_name}/go-ethereum.upstart.conf.erb"),
    require => Golang::Install["go-ethereum"]
  }

  file { "/etc/init.d/go-ethereum":
    ensure    => "link",
    target    => "/lib/init/upstart-job",
    require   => File["/etc/init/go-ethereum.conf"]
  }

  ufw::allow { 'open-port-go-ethereum': port => $inbound_port }

  service { "go-ethereum":
    ensure    => "running",
    provider  => "upstart",
    require   => [
      File["/etc/init.d/go-ethereum"],
      Ufw::Allow['open-port-go-ethereum']
    ],
    subscribe => File["/etc/init.d/go-ethereum"]
  }

}
