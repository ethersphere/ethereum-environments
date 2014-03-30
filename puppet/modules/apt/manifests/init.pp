class apt {

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
  }

  package { [ 'apt-file', 'apt-transport-https', 'python-software-properties' ]:
    ensure => present,
  }

  Exec["apt-get update"] -> Package <| |>

}

define apt::ppa() {
  exec { "/usr/bin/add-apt-repository $title -y": }
}

define apt::add_key( $keyserver = 'keyserver.ubuntu.com', $key = $title ) {
  exec { "/usr/bin/apt-key adv --keyserver $keyserver --recv-keys $key":
    unless => "/usr/bin/apt-key finger | /bin/grep fingerprint | /usr/bin/tr -d ' ' | /bin/grep $key",
  }
}

define apt::unattended_upgrade() {

  package { 'unattended-upgrades':
    ensure => present,
  }

  file { '/etc/apt/apt.conf.d/20auto-upgrades':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => 644,
    source  => 'puppet:///modules/apt/20auto-upgrades',
    require => Package['unattended-upgrades'],
  }

  file { '/etc/apt/apt.conf.d/50unattended-upgrades':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => 644,
    source  => 'puppet:///modules/apt/50unattended-upgrades',
    require => Package['unattended-upgrades'],
  }

}
