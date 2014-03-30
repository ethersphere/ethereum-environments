class go-ethereum {

  include apt
  include golang
  include system_service

  # this is the same as include but allows parameters
  # if specific version of go needed:
  # class { 'golang':
  #   version =>  '2:1.2.1-2ubuntu1'
  # }

  $deps = ['libgmp3-dev',
      'pkg-config',
      'mercurial',
      'libleveldb1'
      ]

  package { [$deps]:
    ensure => present,
  }

  $source = 'github.com/ethereum/go-ethereum/ethereum'
  $ethereum = 'go-ethereum'
  $daemon_path = hiera('go-ethereum::cli_path')

  golang::install { $ethereum:
    source => $source,
    binary => 'ethereum',
    destination => $daemon_path,
  }

  $log_file = hiera('go-ethereum::log_file')

  #hack: doesnt work...
#   $daemon_wrapper_path = "${daemon_path}.sh"

#   file { $daemon_wrapper_path:
#     ensure => present,
#     mode => 755,
#     content => "#!/bin/bash
# ${daemon_path} \$*>> $log_file 2>&1",
#     require => Golang::Install[$ethereum]
#   }

  $pid_file = hiera('go-ethereum::pid_file')
  $data_dir = hiera('go-ethereum::data_dir')
  $outbound_port = hiera('go-ethereum::outbound_port')
  $max_peer = hiera('go-ethereum::max_peer')
  $config_file = hiera('go-ethereum::config_file')

  file { $config_file:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => 644,
    content  => "# from go-ethereum/ethereum/config.go:
USER=ethereum
LOG_FILE=${log_file}
PID_FILE=${pid_file}
START_MINING=1
USE_SEED=1
DATA_DIR=${data_dir}
OUTBOUND_PORT=${outbound_port}
MAX_PEER=${max_peer}
# GEN_ADDR=1
# EXPORT_KEY=
# IMPORT_KEY",
    notify => Service[$ethereum],
  }

  # USE_SEED => -seed
  # START_MINING => -m
  # log file not supported yet?
  # --logfile $LOG_FILE"
  # -dir $DATA_DIR does not work for absolute path ???
  $daemon_args = '"-m -x $MAX_PEER  -p $OUTBOUND_PORT"'

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
    daemon_path => $daemon_wrapper_path,
    daemon_args => $daemon_args,
    require => [File[$config_file],File[$daemon_wrapper_path]]
  }

  service { $ethereum:
    enable => true,
    ensure => running,
    require => System_service::Make[$ethereum],
    subscribe => File[$config_file]
  }

}
