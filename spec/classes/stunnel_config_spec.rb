require 'spec_helper'

describe 'stunnel_config', :type => 'class' do

  global_file   = { '/etc/stunnel/stunnel.pem' => {
         'ensure'      => 'present', 
         'owner'       => 'root', 
         'group'       => 'root', 
         'content'     => 'this is the global level file' } 
  }

  global_tunnel = { 'rsync' => {
         'accept'      => '8873',
         'connect'     => '873',
         'certificate' => '/etc/stunnel/stunnel.pem',
         'chroot'      => '/var/lib/stunnel4/',
         'user'        => 'stunnel4',
         'group'       => 'stunnel4',
         'pid_file'    => '/stunnel4-rsync.pid',
         'ssl_options' => 'NO_SSLv2',
         'client'      => false,
         'foreground'  => false }
  }

  host_file_merge_off = {'stunnel_config::merge_files' => false}

  host_file_merge_on  = {'stunnel_config::merge_files' => true}

  host_tunnel_merge_off = {'stunnel_config::merge_tunnels' => false}

  host_tunnel_merge_on  = {'stunnel_config::merge_tunnels' => true}

  host_file     = { 'stunnel_config::create_files' => { 
    '/etc/stunnel/client.pem' => {
         'ensure'      => 'present', 
         'owner'       => 'root', 
         'group'       => 'root', 
         'content'     => 'this is the host level file' }
    }
  }

  host_tunnel   = {'stunnel_config::tuns' => { 
    'mysql' => {
         'accept'      => '13306',
         'connect'     => '3306',
         'certificate' => '/etc/stunnel/stunnel.pem',
         'chroot'      => '/var/lib/stunnel4/',
         'user'        => 'stunnel4',
         'group'       => 'stunnel4',
         'pid_file'    => '/stunnel4-mysql.pid',
         'ssl_options' => 'NO_SSLv2',
         'client'      => false,
         'foreground'  => false }
    }
  }

  context "Should contain stunnel sysvinit service on RedHat type systems and have only global files/tunnels present" do

    let(:params) {
      { :create_files => global_file,
        :tuns => global_tunnel
      }
    }

    let(:facts) {{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '6',
      :operatingsystem => 'CentOS'
    }}

    it do
      should contain_class('stunnel')
      should contain_file('/etc/stunnel/stunnel.pem').with(
          'content'     => 'this is the global level file'
      )
      should_not contain_file('/etc/systemd/system/stunnel.target')
      should_not contain_service('stunnel-rsync')      
      should_not contain_file('/etc/stunnel/client.pem')
      should contain_service('stunnel')
      should_not contain_service('stunnel4')
      should contain_stunnel__tun('rsync').with(
          'accept'      => '8873',
          'connect'     => '873',
          'certificate' => '/etc/stunnel/stunnel.pem',
          'chroot'      => '/var/lib/stunnel4/',
          'user'        => 'stunnel4',
          'group'       => 'stunnel4',
          'pid_file'    => '/stunnel4-rsync.pid',
          'ssl_options' => 'NO_SSLv2',
          'client'      => false,
          'foreground'  => false,
          'debug_level' => '0',
          'verify'      => '1'
    )
    should_not contain_stunnel__tun('mysql')
    end
  end

    context "Should contain stunnel systemd service and target on RedHat >= 7 type systems and have only global files/tunnels present" do

    let(:params) {
      { :create_files => global_file,
        :tuns => global_tunnel
      }
    }

    let(:facts) {{
      :osfamily     => 'RedHat',
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '7' 
    }}

    it do
      should contain_class('stunnel')
      should contain_file('/etc/stunnel/stunnel.pem').with(
          'content'     => 'this is the global level file'
      )
      should_not contain_file('/etc/stunnel/client.pem')
      should contain_file('/etc/systemd/system/stunnel.target')
      should contain_service('stunnel-rsync')
      should_not contain_service('stunnel')
      should_not contain_service('stunnel4')
      should contain_stunnel__tun('rsync').with(
          'accept'      => '8873',
          'connect'     => '873',
          'certificate' => '/etc/stunnel/stunnel.pem',
          'chroot'      => '/var/lib/stunnel4/',
          'user'        => 'stunnel4',
          'group'       => 'stunnel4',
          'pid_file'    => '/stunnel4-rsync.pid',
          'ssl_options' => 'NO_SSLv2',
          'client'      => false,
          'foreground'  => false,
          'debug_level' => '0',
          'verify'      => '1'
    )
    should_not contain_stunnel__tun('mysql')
    end
  end

  context "Should contain stunnel4 sysvinit service on Debian type systems and have only global files/tunnels present" do

    let(:params) {
      { :create_files => global_file,
        :tuns => global_tunnel
      }
    }

    let(:facts) {{
      :osfamily     => 'Debian',
      :operatingsystemrelease => '14',
      :operatingsystem => 'Debian'
    }}

    it do
      should contain_class('stunnel')
      should contain_file('/etc/stunnel/stunnel.pem').with(
          'content'     => 'this is the global level file'
      )
      should_not contain_file('/etc/systemd/system/stunnel.target')
      should_not contain_service('stunnel-rsync') 
      should_not contain_file('/etc/stunnel/client.pem')
      should_not contain_service('stunnel')
      should contain_service('stunnel4')
      should contain_stunnel__tun('rsync').with(
	        'accept'      => '8873',
	        'connect'     => '873',
	        'certificate' => '/etc/stunnel/stunnel.pem',
	        'chroot'      => '/var/lib/stunnel4/',
	        'user'        => 'stunnel4',
	        'group'       => 'stunnel4',
	        'pid_file'    => '/stunnel4-rsync.pid',
	        'ssl_options' => 'NO_SSLv2',
	        'client'      => false,
	        'foreground'  => false,
	        'debug_level' => '0',
	        'verify'      => '1'
	  )
    should_not contain_stunnel__tun('mysql')
    end
  end

  context "Should configure stunnel with both global/host files/tunnels present and should merge them" do

    let(:params) {
      { :create_files => global_file,
        :tuns => global_tunnel
      }
    }

    let(:facts) {{
      :host => host_tunnel.merge(host_file),
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7',
      :operatingsystem => 'CentOS'
    }}

    it do
      should contain_class('stunnel')
      should contain_file('/etc/stunnel/stunnel.pem').with(
          'content'     => 'this is the global level file'
      )
      should contain_file('/etc/stunnel/client.pem').with(
          'content'     => 'this is the host level file'
      )
      should contain_stunnel__tun('rsync').with(
          'accept'      => '8873',
          'connect'     => '873',
          'certificate' => '/etc/stunnel/stunnel.pem',
          'chroot'      => '/var/lib/stunnel4/',
          'user'        => 'stunnel4',
          'group'       => 'stunnel4',
          'pid_file'    => '/stunnel4-rsync.pid',
          'ssl_options' => 'NO_SSLv2',
          'client'      => false,
          'foreground'  => false,
          'debug_level' => '0',
          'verify'      => '1'
      )
      should contain_stunnel__tun('mysql').with(
          'accept'      => '13306',
          'connect'     => '3306',
          'certificate' => '/etc/stunnel/stunnel.pem',
          'chroot'      => '/var/lib/stunnel4/',
          'user'        => 'stunnel4',
          'group'       => 'stunnel4',
          'pid_file'    => '/stunnel4-mysql.pid',
          'ssl_options' => 'NO_SSLv2',
          'client'      => false,
          'foreground'  => false,
          'debug_level' => '0',
          'verify'      => '1'
    )
    end
  end

  context "Should configure stunnel with both global/host files/tunnels present and should NOT merge either" do

    let(:params) {
      { :create_files => global_file,
        :tuns => global_tunnel
      }
    }

    let(:facts) {{
      :host => host_tunnel.merge(host_file).merge(host_file_merge_off).merge(host_tunnel_merge_off),
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7',
      :operatingsystem => 'CentOS'
    }}

    it do
      should contain_class('stunnel')
      should_not contain_file('/etc/stunnel/stunnel.pem')
      should contain_file('/etc/stunnel/client.pem').with(
          'content'     => 'this is the host level file'
      )
      should_not contain_stunnel__tun('rsync')
      should contain_stunnel__tun('mysql').with(
          'accept'      => '13306',
          'connect'     => '3306',
          'certificate' => '/etc/stunnel/stunnel.pem',
          'chroot'      => '/var/lib/stunnel4/',
          'user'        => 'stunnel4',
          'group'       => 'stunnel4',
          'pid_file'    => '/stunnel4-mysql.pid',
          'ssl_options' => 'NO_SSLv2',
          'client'      => false,
          'foreground'  => false,
          'debug_level' => '0',
          'verify'      => '1'
    )
    end
  end

  context "Should configure stunnel with both global/host files/tunnels present and should NOT merge files" do

    let(:params) {
      { :create_files => global_file,
        :tuns => global_tunnel
      }
    }

    let(:facts) {{
      :host => host_tunnel.merge(host_file).merge(host_file_merge_off).merge(host_tunnel_merge_on),
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7',
      :operatingsystem => 'CentOS'
    }}

    it do
      should contain_class('stunnel')
      should_not contain_file('/etc/stunnel/stunnel.pem')
      should contain_file('/etc/stunnel/client.pem').with(
          'content'     => 'this is the host level file'
      )
      should contain_stunnel__tun('rsync').with(
          'accept'      => '8873',
          'connect'     => '873',
          'certificate' => '/etc/stunnel/stunnel.pem',
          'chroot'      => '/var/lib/stunnel4/',
          'user'        => 'stunnel4',
          'group'       => 'stunnel4',
          'pid_file'    => '/stunnel4-rsync.pid',
          'ssl_options' => 'NO_SSLv2',
          'client'      => false,
          'foreground'  => false,
          'debug_level' => '0',
          'verify'      => '1'
      )
      should contain_stunnel__tun('mysql').with(
          'accept'      => '13306',
          'connect'     => '3306',
          'certificate' => '/etc/stunnel/stunnel.pem',
          'chroot'      => '/var/lib/stunnel4/',
          'user'        => 'stunnel4',
          'group'       => 'stunnel4',
          'pid_file'    => '/stunnel4-mysql.pid',
          'ssl_options' => 'NO_SSLv2',
          'client'      => false,
          'foreground'  => false,
          'debug_level' => '0',
          'verify'      => '1'
    )
    end
  end

  context "Should configure stunnel with both global/host files/tunnels present and should NOT merge tunnels" do

    let(:params) {
      { :create_files => global_file,
        :tuns => global_tunnel
      }
    }

    let(:facts) {{
      :host => host_tunnel.merge(host_file).merge(host_file_merge_on).merge(host_tunnel_merge_off),
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7',
      :operatingsystem => 'CentOS'
    }}

    it do
      should contain_class('stunnel')
      should contain_file('/etc/stunnel/stunnel.pem').with(
          'content'     => 'this is the global level file'
      )
      should contain_file('/etc/stunnel/client.pem').with(
          'content'     => 'this is the host level file'
      )
      should_not contain_stunnel__tun('rsync')
      should contain_stunnel__tun('mysql').with(
          'accept'      => '13306',
          'connect'     => '3306',
          'certificate' => '/etc/stunnel/stunnel.pem',
          'chroot'      => '/var/lib/stunnel4/',
          'user'        => 'stunnel4',
          'group'       => 'stunnel4',
          'pid_file'    => '/stunnel4-mysql.pid',
          'ssl_options' => 'NO_SSLv2',
          'client'      => false,
          'foreground'  => false,
          'debug_level' => '0',
          'verify'      => '1'
    )
    end
  end

end