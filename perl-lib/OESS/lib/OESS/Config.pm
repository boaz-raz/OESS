#!/usr/bin/perl

use strict;
use warnings;

package OESS::Config;

use Data::Dumper;
use XML::Simple;

=head1 NAME

OESS::Config

=cut

=head1 VERSION

2.0.0

=cut

=head1 SYNOPSIS

use OESS::Config

my $config = OESS::Config->new();

my $local_as = $config->local_as();
my $db_creds = $config->db_credentials();
my $db_server = $config->db_server();

=cut

=head2 new

=cut
sub new {
    my $that  = shift;
    my $class = ref($that) || $that;

    my $logger = Log::Log4perl->get_logger("OESS.Config");

    my %args = (
        config_filename => '/etc/oess/database.xml',
        @_,
    );

    my $self = \%args;

    bless $self, $class;

    $self->{'logger'} = $logger;
    $self->{'config'} = XML::Simple::XMLin($self->{'config_filename'});

    return $self;
}

=head2 local_as

returns the configured local_as number

=cut
sub local_as {
    my $self = shift;

    return $self->{'config'}->{'local_as'};
}

=head2 db_credentials

=cut
sub db_credentials {
    my $self = shift;

    my $creds = $self->{'config'}->{'credentials'};
    my $database = $creds->{'database'};
    my $username = $creds->{'username'};
    my $password = $creds->{'password'};

    return {database => $database,
            username => $username,
            password => $password};
}

=head2 mysql_user

=cut
sub mysql_user {
    my $self = shift;
    return $ENV{MYSQL_USER} || $self->{config}->{credentials}->{username};
}

=head2 mysql_pass

=cut
sub mysql_pass {
    my $self = shift;
    return $ENV{MYSQL_PASS} || $self->{config}->{credentials}->{password};
}

=head2 mysql_host

=cut
sub mysql_host {
    my $self = shift;
    return $ENV{MYSQL_HOST} || 'localhost';
}

=head2 mysql_port

=cut
sub mysql_port {
    my $self = shift;
    return $ENV{MYSQL_PORT} || 3306;
}

=head2 mysql_database

=cut
sub mysql_database {
    my $self = shift;
    return $ENV{MYSQL_DATABASE} || $self->{config}->{credentials}->{database} || 'oess';
}

=head2 rabbitmq_user

=cut
sub rabbitmq_user {
    my $self = shift;
    return $ENV{RABBITMQ_USER} || $self->{config}->{rabbitMQ}->{user};
}

=head2 rabbitmq_pass

=cut
sub rabbitmq_pass {
    my $self = shift;
    return $ENV{RABBITMQ_PASS} || $self->{config}->{rabbitMQ}->{pass};
}

=head2 rabbitmq_host

=cut
sub rabbitmq_host {
    my $self = shift;
    return $ENV{RABBITMQ_HOST} || $self->{config}->{rabbitMQ}->{host} || 'localhost';
}

=head2 rabbitmq_port

=cut
sub rabbitmq_port {
    my $self = shift;
    return $ENV{RABBITMQ_PORT} || $self->{config}->{rabbitMQ}->{port} || 5672;
}

=head2 rabbitmq_vhost

=cut
sub rabbitmq_vhost {
    my $self = shift;
    return $ENV{RABBITMQ_VHOST} || $self->{config}->{rabbitMQ}->{vhost} || '/';
}

=head2 tsds_user

=cut
sub tsds_user {
    my $self = shift;
    return $ENV{TSDS_USER} || $self->{config}->{tsds}->{username};
}

=head2 tsds_pass

=cut
sub tsds_pass {
    my $self = shift;
    return $ENV{TSDS_PASS} || $self->{config}->{tsds}->{password};
}

=head2 tsds_url

=cut
sub tsds_url {
    my $self = shift;
    return $ENV{TSDS_URL} || $self->{config}->{tsds}->{url};
}

=head2 tsds_realm

=cut
sub tsds_realm {
    my $self = shift;
    return $ENV{TSDS_REALM} || $self->{config}->{tsds}->{realm};
}

=head2 oess_netconf_overlay

=cut
sub oess_netconf_overlay {
    my $self = shift;
    return $ENV{OESS_NETCONF_OVERLAY} || $self->{config}->{network_type} || 'vpn-mpls';
}

=head2 fwdctl_enabled

=cut
sub fwdctl_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'fwdctl'});
    return ($self->{'config'}->{'process'}->{'fwdctl'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 fvd_enabled

=cut
sub fvd_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'fvd'});
    return ($self->{'config'}->{'process'}->{'fvd'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 mpls_enabled

=cut
sub mpls_enabled {
    my $self = shift;
    return ($self->{'config'}->{'network_type'} eq 'vpn-mpls') ? 1 : 0;
}

=head2 mpls_fwdctl_enabled

=cut
sub mpls_fwdctl_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'mpls_fwdctl'});
    return ($self->{'config'}->{'process'}->{'mpls_fwdctl'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 mpls_discovery_enabled

=cut
sub mpls_discovery_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'mpls_discovery'});
    return ($self->{'config'}->{'process'}->{'mpls_discovery'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 network_type

Returns one of C<openflow>, C<vpn-mpls>, or C<evpn-vxlan>.

=cut
sub network_type {
    my $self = shift;
    if (!defined $self->{'config'}->{'network_type'}) {
        return 'vpn-mpls';
    }

    my $type = $self->{'config'}->{'network_type'};
    my $valid_types = ['openflow', 'vpn-mpls', 'evpn-vxlan'];
    foreach my $valid_type (@$valid_types) {
        if ($type eq $valid_type) {
            return $type;
        }
    }

    $self->{'logger'}->warn("Invalid network_type $type specified. Using 'vpn-mpls' instead.");
    return 'vpn-mpls';
}

=head2 notification_enabled

=cut
sub notification_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'notification'});
    return ($self->{'config'}->{'process'}->{'notification'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 nox_enabled

=cut
sub nox_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'nox'});
    return ($self->{'config'}->{'process'}->{'nox'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 nsi_enabled

=cut
sub nsi_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'nsi'});
    return ($self->{'config'}->{'process'}->{'nsi'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 openflow_enabled

=cut
sub openflow_enabled {
    my $self = shift;
    return ($self->{'config'}->{'network_type'} eq 'openflow') ? 1 : 0;
}

=head2 traceroute_enabled

=cut
sub traceroute_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'traceroute'});
    return ($self->{'config'}->{'process'}->{'traceroute'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 vlan_stats_enabled

=cut
sub vlan_stats_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'vlan_stats'});
    return ($self->{'config'}->{'process'}->{'vlan_stats'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 watchdog_enabled

=cut
sub watchdog_enabled {
    my $self = shift;
    return 1 if (!defined $self->{'config'}->{'process'}->{'watchdog'});
    return ($self->{'config'}->{'process'}->{'watchdog'}->{'status'} eq 'enabled') ? 1 : 0;
}

=head2 get_cloud_config

=cut
sub get_cloud_config {
    my $self = shift;
    return $self->{'config'}->{'cloud'};
}

=head2 base_url

=cut
sub base_url {
    my $self = shift;
    return $self->{'config'}->{'base_url'};
}

=head2 third_party_mgmt

=cut
sub third_party_mgmt {
    my $self = shift;
    return 'n' if (!defined $self->{'config'}->{'third_party_mgmt'});
    return $self->{'config'}->{'third_party_mgmt'};
}

1;
