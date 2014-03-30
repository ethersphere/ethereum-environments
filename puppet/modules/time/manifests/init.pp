class time {

  package { ntp:
    ensure => present
  }

  package { tzdata:
    ensure => present
  }

  file { '/etc/timezone':
    content => 'Europe/London',
    require => Package['tzdata'],
  }

  exec { 'reconfigure-tzdata':
    command     => '/usr/sbin/dpkg-reconfigure -f noninteractive tzdata',
    subscribe   => File['/etc/timezone'],
    require     => [ Package['tzdata'], File['/etc/timezone'] ],
    refreshonly => true,
  }

}
