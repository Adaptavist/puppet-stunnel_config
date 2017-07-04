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
    # if an older version of redhat use the 'redhat' provider, as 'init' is broken on puppet v4
    elsif ($::osfamily == 'RedHat') {
        $service_provider = 'redhat'
    }
    else {
        $service_provider = 'init'
    }
}
