#this allows us to set custom defaults without changing the upstream stunnel module

define stunnel_config::tun(
    $certificate,
    $user,
    $group,
    $client,
    $accept,
    $connect,
    $private_key    = false,
    $ca_file        = undef,
    $crl_file       = undef,
    $ssl_version    = 'TLSv1',
    $chroot         = undef,
    $pid_file       = "/${name}.pid",
    $debug_level    = '0',
    $log_dest       = "/var/log/${name}.log",
    $conf_dir       = $stunnel::params::conf_dir,
    $verify         = 1,
    $retry          = false,
    $foreground     = false,
    $ssl_options    = undef,
    $socket_options = [],
    $fips           = false,
) {

  # if FIPS is supported pass through the value provided, if not pass through undef (forces template to skip fips directive)
  $fips_supported = $stunnel_config::fips_supported
  if (str2bool($fips_supported) ) {
    $real_fips = $fips
  } else {
    $real_fips = undef
  }

  if ($private_key != 'false' and $private_key != false){
    $real_private_key = $private_key
  } else {
    $real_private_key = false
  }

  $real_client = str2bool($client)

  stunnel::tun { $name:
    certificate    => $certificate,
    private_key    => $real_private_key,
    ca_file        => $ca_file,
    crl_file       => $crl_file,
    ssl_version    => $ssl_version,
    chroot         => $chroot,
    user           => $user,
    group          => $group,
    pid_file       => $pid_file,
    debug_level    => $debug_level,
    log_dest       => $log_dest,
    client         => $real_client,
    accept         => $accept,
    connect        => $connect,
    conf_dir       => $conf_dir,
    verify         => $verify,
    ssl_options    => $ssl_options,
    socket_options => $socket_options,
    fips           => $real_fips
  }


}
