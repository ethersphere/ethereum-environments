class users {

  group { ethereum:
    ensure => present,
  }

  group { 'www-data':
    ensure => present
  }

  user { ethereum:
    ensure  => present,
    comment => 'Ethereum User',
    gid     => ethereum,
    shell   => '/bin/bash',
    home    => '/home/ethereum',
    groups  => ['ethereum', 'www-data'],
    require => Group['ethereum', 'www-data'],
  }

  exec { 'ethereum_homedir':
    command => '/bin/cp -R /etc/skel /home/ethereum; /bin/chown -R ethereum:ethereum /home/ethereum',
    creates => '/home/ethereum',
    require => User['ethereum'],
  }

  file { '/etc/sudoers.d/local':
    owner   => root,
    group   => root,
    ensure  => present,
    mode    => 440,
    source  => 'puppet:///modules/users/sudoers_local',
  }

  file { '/home/ethereum/.ssh':
    ensure  => directory,
    owner   => ethereum,
    group   => ethereum,
    mode    => 600,
    require => Exec['ethereum_homedir'],
  }

  file { '/home/ethereum/.ssh/authorized_keys':
    ensure  => present,
    replace => true,
    owner   => ethereum,
    group   => ethereum,
    mode    => 600,
    require => File['/home/ethereum/.ssh'],
    source  => 'puppet:///modules/users/.ssh/authorized_keys',
  }

  # if the admin user is ubuntu (true by default)
  if hiera(users::ubuntu) {
    file { '/home/ubuntu/.ssh':
      ensure  => directory,
      owner   => ubuntu,
      group   => ubuntu,
      mode    => 600,
    }

    file { '/home/ubuntu/.ssh/authorized_keys':
      ensure  => present,
      replace => true,
      owner   => ubuntu,
      group   => ubuntu,
      mode    => 600,
      require => File['/home/ubuntu/.ssh'],
      source  => 'puppet:///modules/users/.ssh/authorized_keys',
    }
  }

}
