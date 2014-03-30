class system_service {

  define make($service, $service_info, $config_file, $daemon_path, $daemon_args) {

    $service_file = "/etc/init.d/${service}"
    file { $service_file:
      ensure => present,
      mode => 755,
      content => template("system_service/service.erb")
    }
  }

}
