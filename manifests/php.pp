# domainalias:
#   - www: add as well a www.${name} entry
#   - absent: do nothing
#   - default: add the string
# user_provider:
#   - local: user will be crated locally (*default*)
#   - ldap: ldap settings will be passed and ldap authorization
#           is mandatory using webdav as user_access
#   - everything else will currently do noting
# run_mode:
#   - normal: nothing special (*default*)
#   - itk: apache is running with the itk module
#          and run_uid and run_gid are used as vhost users
# run_uid: the uid the vhost should run as with the itk module
# run_gid: the gid the vhost should run as with the itk module
# user_access:
#   - sftp: an sftp only user will be created (*default*)
#   - webdav: a webdav vhost will be created which will point to the webhostings root
# ldap_user: Used if you have set user_provider to `ldap`
#   - absent: $name will be passed
#   - any: any authenticated ldap user will work
#   - everything else will be used as a required ldap username
# php_safe_mode_exec_bins: An array of local binaries which should be linked in the
#                          safe_mode_exec_bin for this hosting
#                          *default*: None
# php_default_charset: default charset header for php.
#                      *default*: absent, which will set the same as default_charset
#                                 of apache
define webhosting::php(
    $ensure = present,
    $uid = 'absent',
    $uid_name = 'absent',
    $gid = 'uid',
    $user_provider = 'local',
    $user_access = 'sftp',
    $webdav_domain = 'absent',
    $webdav_ssl_mode = false,
    $password = 'absent',
    $password_crypted = true,
    $domain = 'absent',
    $domainalias = 'www',
    $server_admin = 'absent',
    $owner = root,
    $group = 'absent',
    $run_mode = 'normal',
    $run_uid = 'absent',
    $run_uid_name = 'absent',
    $run_gid = 'absent',
    $run_gid_name = 'absent',
    $allow_override = 'None',
    $do_includes = false,
    $options = 'absent',
    $additional_options = 'absent',
    $default_charset = 'absent',
    $php_use_smarty = false,
    $php_use_pear = false,
    $php_safe_mode = true,
    $php_safe_mode_exec_bins = 'absent',
    $php_default_charset = 'absent',
    $php_additional_open_basedirs = 'absent',
    $php_additional_options = 'absent',
    $ssl_mode = false,
    $vhost_mode = 'template',
    $vhost_source = 'absent',
    $vhost_destination = 'absent',
    $htpasswd_file = 'absent',
    $nagios_check = 'ensure',
    $nagios_check_domain = 'absent',
    $nagios_check_url = '/',
    $nagios_check_code = 'OK',
    $mod_security = true,
    $ldap_user = 'absent'
){

    if ($group == 'absent') and ($user_access == 'sftp') {
        $real_group = 'sftponly'
    } else {
        if ($group == 'absent') {
            $real_group = 'apache'
        } else {
            $real_group = $group
        }
    }
    if ($uid_name == 'absent'){
      $real_uid_name = $name
    } else {
      $real_uid_name = $uid_name
    }

    webhosting::common{$name:
        ensure => $ensure,
        uid => $uid,
        uid_name => $uid_name,
        gid => $gid,
        user_provider => $user_provider,
        user_access => $user_access,
        webdav_domain => $webdav_domain,
        webdav_ssl_mode => $webdav_ssl_mode,
        password => $password,
        password_crypted => $password_crypted,
        htpasswd_file => $htpasswd_file,
        ssl_mode => $ssl_mode,
        run_mode => $run_mode,
        run_uid => $run_uid,
        run_uid_name => $run_uid_name,
        run_gid => $run_gid,
        run_gid_name => $run_gid_name,
        nagios_check => $nagios_check,
        nagios_check_domain => $nagios_check_domain,
        nagios_check_url => $nagios_check_url,
        nagios_check_code => $nagios_check_code,
        ldap_user => $ldap_user,
    }
    apache::vhost::php::standard{"${name}":
        ensure => $ensure,
        domain => $domain,
        domainalias => $domainalias,
        server_admin => $server_admin,
        group => $real_group,
        allow_override => $allow_override,
        do_includes => $do_includes,
        options => $options,
        additional_options => $additional_options,
        default_charset => $default_charset,
        php_use_smarty => $php_use_smarty,
        php_use_pear => $php_use_pear,
        php_safe_mode => $php_safe_mode,
        php_safe_mode_exec_bins => $php_safe_mode_exec_bins,
        php_default_charset => $php_default_charset,
        php_additional_open_basedirs => $php_additional_open_basedirs,
        php_additional_options => $php_additional_options,
        run_mode => $run_mode,
        ssl_mode => $ssl_mode,
        vhost_mode => $vhost_mode,
        vhost_source => $vhost_source,
        vhost_destination => $vhost_destination,
        htpasswd_file => $htpasswd_file,
        mod_security => $mod_security,
    }
    case $run_mode {
        'itk': {
            if ($run_uid_name == 'absent'){
                $real_run_uid_name = "${name}_run"
            } else {
                $real_run_uid_name = $run_uid_name
            }
            if ($run_gid_name == 'absent'){
                $real_run_gid_name = $name
            } else {
                $real_run_gid_name = $run_gid_name
            }
            Apache::Vhost::Php::Standard[$name]{
              documentroot_owner => $real_uid_name,
              documentroot_group => $real_uid_name,
              documentroot_mode => 0750,
              run_uid => $real_run_uid_name,
              run_gid => $real_run_gid_name,
            }
            if ($user_provider == 'local') {
                Apache::Vhost::Php::Standard[$name]{
                  require => [ User::Sftp_only["${real_uid_name}"], User::Managed["${real_run_uid_name}"] ],
                }
            }
        }
        default: {
            if ($user_provider == 'local') {
                Apache::Vhost::Php::Standard[$name]{
                    require => User::Sftp_only["${real_uid_name}"],
                }
            }
        }
    }
}

