class cpp-ethereum {

  include system_service
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
    'libminiupnpc-dev'
  ]

  package { [$deps]:
    ensure => latest,
  }

  $download_dir = "/tmp/"

  file { $download_dir:
    ensure  => directory
  }

  $build_path = "$download_dir/cpp-ethereum/build"

  exec { 'download':
    cwd => $download_dir,
    command => "git clone https://github.com/ethereum/cpp-ethereum; cd cpp-ethereum; mkdir -p $build_path",
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
    require => [Package[$deps],File[$download_dir]]
  }

  $ethereum = 'cpp-ethereum'
  $build_flags = '-DCMAKE_BUILD_TYPE=Release -DHEADLESS=1 -DCMAKE_THREAD_LIBS_INIT=pthread'

  exec { 'build':
    cwd => $build_path,
    command => "cmake .. ${build_flags}; make; make install",
    timeout => 0, # this can take looong
    require => [Package[$deps],Exec['cryptopp']],
    notify => Service[$ethereum],
  }

  $daemon_path = hiera('cpp-ethereum::cli_path')

  # install config file for cpp-ethereumm system service
  $config_file = hiera('cpp-ethereum::config_file')
  $log_file = hiera('cpp-ethereum::log_file')
  $pid_file = hiera('cpp-ethereum::pid_file')
  $data_dir = hiera('cpp-ethereum::data_dir')
  $outbound_port = hiera('cpp-ethereum::outbound_port')
  $inbound_port = hiera('cpp-ethereum::inbound_port')
  $max_peer = hiera('cpp-ethereum::max_peer')
  $verbosity = hiera('cpp-ethereum::verbosity')
  $mining = hiera('cpp-ethereum::mining')

  #https://github.com/ethereum/cpp-ethereum/wiki/Using-Ethereum-CLI-Client
  file { $config_file:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => 644,
    content  => "
USER=ethereum
LOG_FILE=${log_file}
PID_FILE=${pid_file}
MINING=${mining}
DATA_DIR=${data_dir}
OUTBOUND_PORT=${outbound_port}
INBOUND_PORT=${inbound_port}
MAX_PEER=${max_peer}
VERBOSITY=${verbosity}
# NODE_IP
# REMOTE_IP
# SECRET
# ADDRESS",
    notify => Service[$ethereum],
  }

  # install service
  # note: this system service file is ideally part of the deb package
  # for stable release

  # log file not supported yet?
  # --logfile $LOG_FILE"
  $daemon_args = '"-d $DATA_DIR -o full -m $MINING -x $MAX_PEER -p $OUTBOUND_PORT -l $INBOUND_PORT -v $VERBOSITY"'

  $service_info = "
### BEGIN INIT INFO
# Provides:          ${ethereum}
# Required-Start:    \$remote_fs \$syslog \$network
# Required-Stop:     \$remote_fs \$syslog \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Manages the ethereum node daemon
# Description:       ethereum.org
### END INIT INFO"

  system_service::make { $ethereum:
    service => $ethereum,
    service_info => $service_info,
    config_file => $config_file,
    daemon_path => $daemon_path,
    daemon_args => $daemon_args,
    require => [File[$config_file],Exec['build']]
  }

  ufw::allow { 'open-port-cpp-ethereum': port => $inbound_port }

  service { $ethereum:
    enable => true,
    ensure => running,
    require => [System_service::Make[$ethereum],Ufw::Allow['open-port-cpp-ethereum']],
    subscribe => File[$config_file]
  }

}