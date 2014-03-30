class ufw {

  package { 'ufw':
    ensure => present,
  }

  Package['ufw'] -> Exec['ufw-default-deny'] -> Exec['ufw-enable']

  exec { 'ufw-default-deny':
    command => '/usr/sbin/ufw default deny',
    unless  => '/usr/sbin/ufw status verbose | /bin/grep "Default: deny (incoming), allow (outgoing)"',
  }

  exec { 'ufw-enable':
    command => '/usr/bin/yes | /usr/sbin/ufw enable',
    unless  => '/usr/sbin/ufw status | /bin/grep "Status: active"',
  }

  service { 'ufw':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    subscribe => Package['ufw'],
  }

}

define ufw::allow($proto='tcp', $port='all', $ipadr='any', $from='any') {

  $from_match = $from ? {
    'any'   => 'Anywhere',
    default => $from,
  }

  exec { "ufw-allow-${proto}-from-${from}-to-${ipadr}-port-${port}":
    command => $port ? {
      'all'   => "/usr/sbin/ufw allow proto $proto from $from to $ipadr",
      default => "/usr/sbin/ufw allow proto $proto from $from to $ipadr port $port",
    },
    unless  => "$ipadr:$port" ? {
      'any:all'    => "/usr/sbin/ufw status | /bin/grep -E \" +ALLOW +$from_match\"",
      /[0-9]:all$/ => "/usr/sbin/ufw status | /bin/grep -E \"$ipadr/$proto +ALLOW +$from_match\"",
      /^any:[0-9]/ => "/usr/sbin/ufw status | /bin/grep -E \"$port/$proto +ALLOW +$from_match\"",
      default      => "/usr/sbin/ufw status | /bin/grep -E \"$ipadr $port/$proto +ALLOW +$from_match\"",
    },
    require => Exec['ufw-default-deny'],
    before  => Exec['ufw-enable'],
  }
}

define ufw::deny($proto='tcp', $port='all', $ipadr='any', $from='any') {

  $from_match = $from ? {
    'any'   => 'Anywhere',
    default => "$from/$proto",
  }

  exec { "ufw-deny-${proto}-from-${from}-to-${ipadr}-port-${port}":
    command => $port ? {
      'all'   => "/usr/sbin/ufw deny proto $proto from $from to $ipadr",
      default => "/usr/sbin/ufw deny proto $proto from $from to $ipadr port $port",
    },
    unless  => $port ? {
      'all'   => "/usr/sbin/ufw status | /bin/grep -E \"$ipadr/$proto +DENY +$from_match\"",
      default => "/usr/sbin/ufw status | /bin/grep -E \"$ipadr $port/$proto +DENY +$from_match\"",
    },
    require => Exec['ufw-default-deny'],
    before  => Exec['ufw-enable'],
  }

}

