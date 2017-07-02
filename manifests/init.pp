# Wrapper class for configuring stunnel
class stunnel_config (
    $tuns             = $stunnel_config::params::tuns,
    $create_files     = $stunnel_config::params::create_files,
    $merge_tunnels    = $stunnel_config::params::merge_tunnels,
    $merge_files      = $stunnel_config::params::merge_files,
    $fips_supported   = $stunnel_config::params::fips_supported,
    $service_provider = $stunnel_config::params::service_provider,
) inherits stunnel_config::params {

    validate_re($service_provider, ['^init$', '^systemd$', '^redhat'])

    #tunnels and files can be set at either global or host level, therefore check to see if the hosts hash exists
    if ($::host != undef) {

        validate_hash($::host)

        #if a host level "merge_tunnels" flag has been set use it, otherwise use the global flag
        $merge_host_tunnels = $host['stunnel_config::merge_tunnels'] ? {
            default => $host['stunnel_config::merge_tunnels'],
            undef   => $merge_tunnels
        }

        #if a host level "merge_files" flag has been set use it, otherwise use the global flag
        $merge_host_files = $host['stunnel_config::merge_files'] ? {
            default => $host['stunnel_config::merge_files'],
            undef   => $merge_files
        }

        #if there are host level tunnels
        if ($host['stunnel_config::tuns'] != undef) {
            #and we have merging enabled merge global and host
            if ($merge_host_tunnels) {
                $tunnel_configs = merge($tuns, $host['stunnel_config::tuns'])
            } else {
                $tunnel_configs = $host['stunnel_config::tuns']
            }
        }
        #if there are no host level stunnel modules just use globals
        else {
            $tunnel_configs = $tuns
        }

        #if there are host level files
        if ($host['stunnel_config::create_files'] != undef) {
            #and we have merging enabled merge global and host
            if ($merge_host_files) {
                $files_to_create = merge($create_files, $host['stunnel_config::create_files'])
            } else {
                $files_to_create = $host['stunnel_config::create_files']
            }
        }
        #if there are no host files to create use globals
        else {
            $files_to_create = $create_files
        }
    }
    #if there is no host has use global values
    else {
      $tunnel_configs = $tuns
      $files_to_create = $create_files
    }

    #include the stunnel class to actually install stunnel etc
    include stunnel
    $stunnel_service  = $stunnel::params::service

    if ($service_provider == 'init' or $service_provider == 'redhat') {
        $stunnel_service_require = [Service[$stunnel_service]]
        $service_restart_command = "service ${stunnel_service} restart"
        # RedHat based systems do not have an sysvinit script for stunnel
        # Create one based on the Ubuntu sysvinit script
        if ($::osfamily == 'RedHat' ) {
            # create init script
            file { "/etc/init.d/${stunnel_service}":
                content => template("${name}/stunnel-sysvinit.erb"),
                owner   => 'root',
                group   => 'root',
                mode    => '0755',
                require => Class['stunnel'],
            }
            service { $stunnel_service:
                ensure     => running,
                provider   => $service_provider,
                enable     => true,
                hasrestart => true,
                hasstatus  => false,
                require    => File["/etc/init.d/${stunnel_service}"],
            }
        }
    } else {
        # crate a systemd stunnel target, each stunnel tunnel will have its own systemd service that is partof/wantedby this target unit
        $stunnel_service_require = [File['/etc/systemd/system/stunnel.target'],Exec['register stunnel target']]
        $service_restart_command= 'systemctl restart stunnel.target'
        file { '/etc/systemd/system/stunnel.target':
            content => template("${name}/stunnel-systemd-target.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => Class['stunnel'],
        } -> exec { 'register stunnel target':
            command => 'systemctl enable stunnel.target',
            path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        }
    }

    if ($files_to_create) {
        validate_hash($files_to_create)
        $create_files_defaults = {
            require => Package[$stunnel::params::package],
            before => $stunnel_service_require,
        }
        create_resources(file, $files_to_create, $create_files_defaults)
    }

    validate_hash($tunnel_configs)

    $create_tuns_defaults = {
        'notify' => Exec['restart stunnel'],
        require => $stunnel_service_require,
    }
    create_resources(stunnel_config::tun, $tunnel_configs, $create_tuns_defaults)
    Stunnel_config::Tun<| |> -> Exec['restart stunnel']
    exec { 'restart stunnel':
        command => $service_restart_command,
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        require => $stunnel_service_require,
    }
}
