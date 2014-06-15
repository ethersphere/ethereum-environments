class cpp-ethereum {

  include ufw

  $deps = [
    'build-essential',
    'g++-4.8',
    'git',
    'cmake',
    'automake',
    'libtool',
    'unzip',
    'yasm',
    'libncurses5-dev',
    'libgmp-dev',
    'libgmp3-dev',
    # 'libcrypto++-dev', # only 5.6.1
    'libboost-all-dev',  # 1.54
    'libleveldb-dev',
    'libminiupnpc-dev',
    'libreadline-dev',
    'libcurl4-openssl-dev'
  ]

  $gui_deps = [
    'qtbase5-dev',
    'qt5-default',
    'qtdeclarative5-dev',
    'libqt5webkit5-dev'
  ]

  package { [$deps]:
    ensure => latest,
  }

  if ($gui == 'true') {
    package { [$gui_deps]:
      ensure => latest,
    }
    $all_deps = [$deps, $gui_deps]
  } else {
    $all_deps = $deps
  }

  $download_dir = "/tmp/"

  file { $download_dir:
    ensure  => directory
  }

  $build_path = "$download_dir/cpp-ethereum/build"

  exec { 'download':
    cwd => $download_dir,
    command => "git clone https://github.com/ethereum/cpp-ethereum; cd cpp-ethereum; git checkout $branch; mkdir -p $build_path",
    require => File[$download_dir]
  }

  file { $build_path:
    ensure => directory,
    require => Exec['download']
  }

  exec { 'cryptopp':
    cwd => $build_path,
    command => "mkdir cryptopp562;
cd cryptopp562;
wget http://www.cryptopp.com/cryptopp562.zip;
unzip -a cryptopp562.zip;
CXX='g++ -fPIC' make;
make dynamic;
sudo make install || echo # cos no exe built
",
    timeout => 0, # this can take looong
    require => [Package[$all_deps],File[$download_dir]]
  }

  $ethereum = 'cpp-ethereum'

  if ($gui == 'true') {
    $build_flags = '-DCMAKE_BUILD_TYPE=Release -DHEADLESS=1 -DCMAKE_THREAD_LIBS_INIT=pthread'
  } else {
    $build_flags = '-DCMAKE_BUILD_TYPE=Release -DCMAKE_THREAD_LIBS_INIT=pthread'
  }

  exec { 'build':
    cwd => $build_path,
    command => "cmake .. ${build_flags}; make; make install",
    timeout => 0, # this can take looong
    require => [Package[$deps],Exec['cryptopp']],
  }

  $daemon_path = hiera('cpp-ethereum::cli_path')
  $log_file = hiera('cpp-ethereum::log_file')
  $data_dir = hiera('cpp-ethereum::data_dir')
  $outbound_port = hiera('cpp-ethereum::outbound_port')
  $inbound_port = hiera('cpp-ethereum::inbound_port')
  $max_peer = hiera('cpp-ethereum::max_peer')
  $verbosity = hiera('cpp-ethereum::verbosity')
  $dirs = hiera('cpp-ethereum::dirs')

  file { $dirs:
    ensure => directory,
    owner  => ethereum,
    group  => ethereum,
    mode   => "0640",
  }

  file { "/etc/init/cpp-ethereum.conf":
    ensure    => "file",
    content   => template("${module_name}/cpp-ethereum.upstart.conf.erb"),
    require => Exec['build']
  }

  file { "/etc/init.d/cpp-ethereum":
    ensure    => "link",
    target    => "/lib/init/upstart-job",
    require   => File["/etc/init/cpp-ethereum.conf"]
  }

  ufw::allow { 'open-port-cpp-ethereum': port => $inbound_port }

  if ($gui == 'true') {
    $service = "stopped"
  } else {
    $service = "running"
  }

  service { "cpp-ethereum":
    ensure    => $service,
    provider  => "upstart",
    require   => [
      File["/etc/init.d/cpp-ethereum"],
      File[$dirs],
      Ufw::Allow['open-port-cpp-ethereum']
    ],
    subscribe => File["/etc/init.d/cpp-ethereum"]
  }

}