import 'variables.pp'

class pgsql {
  service { 'postgresql':
    name      => 'postgresql',
###    ensure    => running,
    enable    => true,
    subscribe => Package['postgresql-server'],
  }

  package { 'postgresql-server':
    name   => 'postgresql-server',
    ensure => installed,
  }   

  file { '/var/lib/pgsql/data/postgresql.conf':
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0600',
    source  => "$manifest_dir/dist/postgresql.conf",
    notify  => Service['postgresql'],
    require => Exec['initdb'],
  }

  file { '/var/lib/pgsql/data/pg_hba.conf':
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0600',
    source  => "$manifest_dir/dist/pg_hba.conf",
    notify  => Service['postgresql'],
    require => Exec['initdb'],
  }

  exec {
    'initdb':
      path      => '/sbin',
      command   => 'service postgresql initdb',
      logoutput => true,
      creates   => '/var/lib/pgsql/data/PG_VERSION',
      before    => Service['postgresql'],
      require   => Package['postgresql-server'],
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
      before      => [Service['postgresql'],
                      File['/var/lib/pgsql/data/pg_hba.conf']],
    ;
  }
}

include 'pgsql'
