node basenode {

  # APT setup with security updates

  include apt

  apt::unattended_upgrade { 'enable-unattended-upgrades': }

  # Enable firewall and close all ports other 22 and 80

  include ufw

  ufw::allow { 'open-port-22': port => 22 }
  # ufw::allow { 'open-port-80': port => 80 }

  # Fail2ban with ssh protection

  include fail2ban

  fail2ban::jail { 'ssh': }
  fail2ban::jail { 'ssh-ddos': }

  # SSH with default config

  include sshd

  sshd::default_config { 'setup-sshd-config': }

  include time
  include users

  Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin/:/usr/local/bin" }

}
