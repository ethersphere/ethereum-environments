class go-ethereum {

  include golang
  include ufw

  $deps = [
    'libgmp3-dev',
    'pkg-config',
    'mercurial',
    'libleveldb1',
    'libreadline6-dev'
  ]

  $gui_deps = [
    'ubuntu-sdk',
    'qtbase5-private-dev',
    'qtdeclarative5-private-dev',
    'libqt5opengl5-dev'
  ]

  package { [$deps]:
    ensure => present,
  }

  if ($gui == 'true') {
    $ppa='ppa:ubuntu-sdk-team/ppa'
    apt::ppa { $ppa: }
    package { [$gui_deps]:
      ensure => latest,
      require => Apt::Ppa[$ppa]
    }
    $eth_deps = ["go-ethereum", "go-ethereal"]
    golang::install { "go-ethereal":
      source => 'github.com/ethereum/go-ethereum/ethereal',
      binary => "ethereal",
      destination => "/usr/local/bin/ethereal",
      branch => $branch,
      require => [Package[$deps, $gui_deps],Golang::Compile['eth-go']]
    }
  } else {
    $eth_deps = "go-ethereum"
  }

  # compile from source
  $daemon_path = hiera('go-ethereum::cli_path')

  golang::compile { "eth-go":
    source => 'github.com/ethereum/eth-go',
    branch => $branch,
    require => Package[$deps]
  }

  # I have no idea how go can get away without version management - it's a mystery
  golang::install { "go-ethereum":
    source => 'github.com/ethereum/go-ethereum/ethereum',
    binary => "ethereum",
    destination => $daemon_path,
    branch => $branch,
    require => [Package[$deps],Golang::Compile['eth-go']]
  }

  # config variables for go-ethereum upstart service conf file
  $log_file = hiera('go-ethereum::log_file')
  $data_dir = hiera('go-ethereum::data_dir') #-datadir only in develop as o 2014-06-14
  $outbound_port = hiera('go-ethereum::outbound_port')
  $inbound_port = hiera('go-ethereum::inbound_port') # only used to open port
  $max_peer = hiera('go-ethereum::max_peer')
  $dirs = hiera('go-ethereum::dirs')

  file { $dirs:
    ensure => directory,
    owner  => ethereum,
    group  => ethereum,
    mode   => "0640",
  }

  file { "/etc/init/go-ethereum.conf":
    ensure    => "file",
    content   => template("${module_name}/go-ethereum.upstart.conf.erb"),
    require => Golang::Install[$eth_deps]
  }

  file { "/etc/init.d/go-ethereum":
    ensure    => "link",
    target    => "/lib/init/upstart-job",
    require   => File["/etc/init/go-ethereum.conf"]
  }

  ufw::allow { 'open-port-go-ethereum': port => $inbound_port }

  if ($gui == 'true') {
    $service = "stopped"
  } else {
    $service = "running"
  }

  service { "go-ethereum":
    ensure    => $service,
    provider  => "upstart",
    require   => [
      File["/etc/init.d/go-ethereum"],
      File[$dirs],
      Ufw::Allow['open-port-go-ethereum']
    ],
    subscribe => File["/etc/init.d/go-ethereum"]
  }

}
