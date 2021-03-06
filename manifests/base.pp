package {'sudo':
  ensure => present
}->
package{'zip':
  ensure => present
}

package{'dos2unix':
  ensure => present
}

package{'perl':
  ensure => present
}



file{ '/etc/yum.repos.d/epel.repo':
  ensure => present,
  content => '[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=0'
}

#java-1.8.0-openjdk-1.8.0.212.b04-0.el7_6
#java-11-openjdk-11.0.3.7-0.el7_6


if $java_version == '11'
{
  $java_package = "java-${java_version}-openjdk-${java_version}.0.${java_version_update}.${java_version_build}-0.el7_6"
}
else
{
  $java_package = "java-1.${java_version}.0-openjdk-1.${java_version}.0.${java_version_update}.b${java_version_build}-0.el7_6"
}

class { 'java':
  package  => $java_package,
}

# class { 'jdk_oracle':
  # version     => $java_version,
  # install_dir => $java_home,
  # version_update => $java_version_update,
  # version_build  => $java_version_build,
  # version_hash  => $java_version_hash,
  # package     => 'server-jre'
# }

-> file { '/etc/pki/tls/certs/java':
  ensure  => directory
}

-> file { '/etc/pki/tls/certs/java/cacerts':
  ensure  => link,
  target  => '/etc/pki/ca-trust/extracted/java/cacerts'
}

-> file { '/usr/lib/jvm/jre/lib/security/cacerts':
  ensure  => link,
  target  => '/etc/pki/tls/certs/java/cacerts'
}


class { 'confluence':
  version        => $confluence_version,
  installdir     => $confluence_installdir,
  homedir        => $confluence_home,
  javahome       => $java_home,
  manage_service => false,
  require        => [Package['perl'], File['/usr/lib/jvm/jre/lib/security/cacerts']]

}

$real_appdir = "${confluence_installdir}/atlassian-confluence-${confluence_version}"


#http://download.oracle.com/otn/utilities_drivers/jdbc/122010/ojdbc8.jar

/*exec {'wget and disable wget':
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  cwd     => "${real_appdir}/lib",
  command => 'wget http://download.oracle.com/otn/utilities_drivers/jdbc/122010/ojdbc8.jar; chmod -x /usr/bin/wget',
  require => Class['confluence']
} */

file {'/opt/confluence-config':
  ensure  => directory,
  source  => "file:///${real_appdir}/conf",
  require => Class['confluence'],
  recurse => 'true'
} ->

file {'/opt/scripts/fixline.sh':
  mode    => '0777',
  content => 'find . -iname \'*.sh\' | xargs dos2unix',
  require => Package['dos2unix']
} ->

# Fix dos2unix
exec {'dos2unix-fix':
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  cwd     => "${real_appdir}/bin",
  command => '/opt/scripts/fixline.sh'
} ->

exec {'dos2unix-fix-start-service':
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  cwd     => "/opt/scripts",
  command => '/opt/scripts/fixline.sh'
} ->

file { '/usr/bin/start-service':
  ensure => link,
  target => '/opt/scripts/start-service.sh',
}

exec {'Fix permissions':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => "chown -R confluence:confluence ${confluence_home}",
  require => Class['confluence']
} ->

exec {'Fix permissions2':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => "chown -R confluence:confluence ${$real_appdir}"
} ->


# Full update
exec {'Full update':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'yum -y update ; chmod -x /bin/curl', 
  require => Class['confluence']
} ->
# Cleaning unused packages to decrease image size
exec {'erase installer':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'rm -rf /tmp/*; rm -rf /opt/staging/*'
} ->

exec {'erase cache':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'rm -rf /var/cache/*'
} ->
exec {'erase logs':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'rm -rf /var/log/*'
}


package {'openssh': ensure => absent }
package {'openssh-clients': ensure => absent }
package {'openssh-server': ensure => absent }
package {'rhn-check': ensure => absent }
package {'rhn-client-tools': ensure => absent }
package {'rhn-setup': ensure => absent }
package {'rhnlib': ensure => absent }
package{'wget': ensure => absent }


package {'/usr/share/kde4':
  ensure => absent
}
