class golang(
  $version = 'present'
) {

  package { 'golang':
    ensure  => $version,
  }

  package { 'git':
    ensure  => latest,
  }

  $gopath = "/usr/local/share/go/share"
  $gopathdirs = ["/usr/local/share/go", "/usr/local/share/go/share"]

  file { $gopathdirs:
    ensure => directory,
    owner => root,
    group => root,
    mode => 644,
    require => Package['golang']
  }

  define compile ($source, $binary) {
    exec { 'get':
      environment => "GOPATH=${Golang::gopath}",
      command => "go get -v ${source}",
      require => [Package['golang', 'git'],File[$Golang::gopathdirs]]
    }
    $build_path = "${Golang::gopath}/src/${source}"
    exec { 'build':
      environment => "GOPATH=${Golang::gopath}",
      cwd => $build_path,
      unless => "ls $build_path/$binary",
      command => "go build -v",
      require => Exec['get']
    }
  }

  define install ($source, $binary, $destination) {

    golang::compile { $binary:
      source => $source,
      binary => $binary
    }

    file { $destination:
      ensure => present,
      source => "${Golang::gopath}/src/${source}/${binary}",
      require => Golang::Compile[$binary]
    }
  }

}