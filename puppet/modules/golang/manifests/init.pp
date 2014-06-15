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

  define compile ($source, $branch) {
    exec { "get $source":
      environment => "GOPATH=${Golang::gopath}",
      command => "go get -v ${source}",
      require => [Package['golang', 'git'],File[$Golang::gopathdirs]]
    }
    $build_path = "${Golang::gopath}/src/${source}"
    exec { "build $source":
      environment => "GOPATH=${Golang::gopath}",
      cwd => $build_path,
      command => "git checkout ${branch}; go build -v",
      require => Exec["get $source"]
    }
  }

  define install ($source, $binary, $destination, $branch) {

    golang::compile { $binary:
      source => $source,
      branch => $branch
    }

    file { $destination:
      ensure => present,
      source => "${Golang::gopath}/src/${source}/${binary}",
      require => Golang::Compile[$binary]
    }
  }

}