class fail2ban {

  package { 'fail2ban':
    ensure => present,
  }

  service { 'fail2ban':
    ensure => running,
  }

}

define fail2ban::jail() {

  include fail2ban

  exec { "add-fail2ban-jail-${name}":
    command => "/bin/echo -e \"[${name}]\nenabled = true\n\" >> /etc/fail2ban/jail.local",
    unless  => "/bin/cat /etc/fail2ban/jail.local | /bin/grep -A 1 \"\\[${name}\\]\" | grep \"enabled = true\"",
    notify  => Service['fail2ban'],
    require => Package['fail2ban'],
  }

}
