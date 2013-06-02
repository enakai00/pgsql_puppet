class pgsql_install {
  package { 'postgresql-server':
    ensure => latest,
  }   
}

class pgsql_service {
  service { 'postgresql':
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
    enable     => true,
  }
}

class pgsql_init {
  file { '/var/lib/pgsql/data/postgresql.conf':
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0600',
    source  => "$manifest_dir/dist/postgresql.conf",
    require => [Exec['initdb'], Exec['init_pw']],
  }

  file { '/var/lib/pgsql/data/pg_hba.conf':
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0600',
    source  => "$manifest_dir/dist/pg_hba.conf",
    require => [Exec['initdb'], Exec['init_pw']],
  }

  exec {
    'initdb':
      path      => '/sbin',
      command   => 'service postgresql initdb',
      logoutput => true,
      creates   => '/var/lib/pgsql/data/PG_VERSION',
      notify    => Exec['init_pw'],
    ;

    'init_pw':
      path        => ['/sbin', '/bin'],
      command     => 'service postgresql start && \
                      su - postgres -c "psql -w -c \
               \"ALTER USER postgres encrypted password \'pas4pgsql\'\"" && \
                      service postgresql stop',
      logoutput   => true,
      refreshonly => true,
    ;
  }
}

import 'variables.pp'

include 'pgsql_install'
include 'pgsql_init'
include 'pgsql_service'

Class['pgsql_install'] -> Class['pgsql_init'] ~> Class['pgsql_service']
Class['pgsql_install'] ~> Class['pgsql_service']

