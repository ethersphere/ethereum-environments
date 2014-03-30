class sshd {
  service { 'ssh':
    ensure => running,
  }
}

define sshd::default_config {

  include sshd

  file { '/etc/ssh/sshd_config':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => 600,
    notify  => Service['ssh'],
    content => "
  ChallengeResponseAuthentication no
  Ciphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,aes128-cbc,3des-cbc,blowfish-cbc,cast128-cbc,aes192-cbc,aes256-cbc,arcfour
  GSSAPIAuthentication no
  HostKey /etc/ssh/ssh_host_rsa_key
  HostKey /etc/ssh/ssh_host_dsa_key
  HostKey /etc/ssh/ssh_host_ecdsa_key
  HostbasedAuthentication no
  IgnoreRhosts yes
  KerberosAuthentication no
  KeyRegenerationInterval 3600
  LogLevel INFO
  LoginGraceTime 60
  MACs hmac-md5,hmac-sha1,umac-64@openssh.com,hmac-sha2-256,hmac-sha2-512,hmac-ripemd160,hmac-sha1-96,hmac-md5-96
  PasswordAuthentication no
  PermitEmptyPasswords no
  PermitRootLogin without-password
  PermitUserEnvironment no
  Port 22
  Protocol 2
  PubKeyAuthentication yes
  RSAAuthentication yes
  RhostsRSAAuthentication no
  ServerKeyBits 768
  StrictModes yes
  SyslogFacility AUTH
  Subsystem       sftp    /usr/lib/sftp-server
  UseDNS no
  UseLogin no
  UsePAM yes
  UsePrivilegeSeparation yes
  X11Forwarding no
    ",
  }

}
