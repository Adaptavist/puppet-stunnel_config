class stunnel_config::params {
    $tuns             =    {}
    $create_files     =    {}
    $merge_tunnels    =    true
    $merge_files      =    true
    $fips_supported   =    'false'

    # if this is CentOS/RHEL >= 7 install set the service provider to systemd, otherwise set it to init
    if ($::osfamily == 'RedHat') and (versioncmp($::operatingsystemrelease,'7') >= 0 and $::operatingsystem != 'Fedora') {
        $service_provider = 'systemd'
    }
    else {
        $service_provider = 'init'
    }
}