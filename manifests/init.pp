# @summary Configure metrics grafana services
#
# @param cilogon_client_id
#   CILogon OIDC client ID
#
# @param cilogon_client_secret
#   CILogon OIDC client secret
#
# @param db_name
#   Name of MySQL database used by grafana
#
# @param db_passwd
#   Password of MySQL database user for grafana
#
# @param db_user
#   Username of MySQL database user for grafana
#
# @param grafana_server_root_url
#   root_url for grafana server including protocol
#
# @param grafana_version
#   optional version of grafana installed
#
# @example
#   include profile_metrics_alerting
class profile_metrics_alerting (
  String $cilogon_client_id,
  String $cilogon_client_secret,
  String $db_name,
  String $db_passwd,
  String $db_user,
  String $grafana_server_root_url,
  String $grafana_version,
) {

  # HTTPD PROXY
  include ::profile_website
  # MARIADB SERVICE
  class { 'mysql::server':
    package_name            => 'mariadb-server',
    remove_default_accounts => true,
    restart                 => true,
  }
  mysql::db { $db_name:
    user     => $db_user,
    password => $db_passwd,
    host     => 'localhost',
    charset  => 'utf8mb4',
    collate  => 'utf8mb4_general_ci',
  }

  # GRAFANA SERVICE
  class { 'grafana':
    cfg     => {
      alerting             => {
        enabled => false,
      },
      analytics            => {
        reporting => true,
      },
      auth                 => {
        login_maximum_inactive_lifetime_duration => '9h',
        login_maximum_lifetime_duration          => '7d',
        disable_login_form                       => true,
        disable_signout_menu                     => true,
      },
      'auth.anonymous'     => {
        enabled      => true,
        hide_version => true,
        org_name     => 'NCSA',
        org_role     => 'Viewer',
      },
      'auth.basic'         => {
        enabled => true,
      },
      'auth.generic_oauth' => {
        allow_sign_up        => true,
        api_url              => 'https://cilogon.org/oauth2/userinfo',
        auth_url             => 'https://cilogon.org/authorize',
        client_id            => $cilogon_client_id,
        client_secret        => $cilogon_client_secret,
        enabled              => true,
        login_attribute_path => 'uid',
        name                 => 'NCSA CILogon',
        role_attribute_path  => 'contains(isMemberOf[*], \'ici_monitoring_admin\') && \'Admin\' || \'Viewer\'',
        scopes               => 'openid,email,profile,org.cilogon.userinfo',
        token_url            => 'https://cilogon.org/oauth2/token',
      },
      'auth.ldap'          => {
#        allow_sign_up => true,
#        config_file   => '/etc/grafana/ldap.toml',
        enabled       => false,
      },
      database             => {
        type     => 'mysql',
        host     => '127.0.0.1:3306',
        name     => $db_name,
        user     => $db_user,
        password => $db_passwd,
      },
      explore              => {
        enabled => false,
      },
      live                 => {
        allowed_origins => '*',
      },
      server               => {
        root_url => $grafana_server_root_url,
      },
      smtp                 => {
        enabled      => true,
        from_address => "root@${$facts['fqdn']}",
        from_name    => 'NCSA ICI Alert Engine',
        host         => 'localhost:25',
        skip_verify  => true,
      },
      unified_alerting     => {
        enabled => true,
      },
      users                => {
        allow_sign_up    => false,
        allow_org_create => false,
      },
    },
    version => $grafana_version,
  }

  include profile_metrics_alerting::alert_cycle
  include profile_metrics_alerting::ssh
  include profile_metrics_alerting::tools

}
