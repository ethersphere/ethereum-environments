class cpp-ethereum {

  $deps = [
    'build-essential',
    'g++-4.8',
    'git',
    'cmake',
    'automake',
    'libtool',
    'unzip',
    'yasm',
    'libgmp-dev',
    'libgmp3-dev',
    # 'libcrypto++-dev', # only 5.6.1
    'libboost-all-dev',  # 1.54
    'libleveldb-dev',
    'libminiupnpc-dev'
  ]

  package { [$deps]:
    ensure => latest,
  }

  $download_dir = "/tmp/"

  file { $download_dir:
    ensure  => directory

  }

  exec { 'download':
    cwd => $download_dir,
    command => "git clone https://github.com/ethereum/cpp-ethereum; cd cpp-ethereum; mkdir -p $build_path",
    require => File[$download_dir]
  }

  $build_path = "$download_dir/cpp-ethereum/build"

  file { $build_path:
    ensure => directory,
    require => Exec['download']
  }

  exec { 'cryptopp':
    cwd => $build_path,
    command => "
mkdir cryptopp562
cd cryptopp562
wget http://www.cryptopp.com/cryptopp562.zip
unzip -a cryptopp562.zip
CXX="g++ -fPIC" make
make dynamic
make install || echo # cos no exe built
",
    require => File[$download_dir]
  }

  $build_flags = '-DCMAKE_BUILD_TYPE=Release -DHEADLESS=1 -DCMAKE_THREAD_LIBS_INIT=pthread'
  exec { 'build':
    cwd => $build_path,
    command => "cmake .. ${build_flags}; make; make install",
    require => [Package[$deps],Exec['cryptopp']]
  }

}