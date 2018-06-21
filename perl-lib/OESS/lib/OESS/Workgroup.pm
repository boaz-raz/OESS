#!/usr/bin/perl

use strict;
use warnings;

package OESS::Workgroup;

use OESS::DB::Workgroup;

sub new{
    my $that  = shift;
    my $class = ref($that) || $that;

    my $logger = Log::Log4perl->get_logger("OESS.Workgroup");

    my %args = (
        vrf_peer_id => undef,
        db => undef,
        just_display => 0,
        link_status => undef,
        @_
        );

    my $self = \%args;

    bless $self, $class;

    $self->{'logger'} = $logger;

    if(!defined($self->{'db'})){
        $self->{'logger'}->error("No Database Object specified");
        return;
    }

    $self->_fetch_from_db();

    return $self;    
    
}

sub from_hash{
    my $self = shift;
    my $hash = shift;

    $self->{'workgroup_id'} = $hash->{'workgroup_id'};
    $self->{'name'} = $hash->{'name'};
    $self->{'admin'} = $hash->{'admin'};

}

sub to_hash{
    my $self = shift;

    my $obj = {};

    $obj->{'workgroup_id'} = $self->workgroup_id();
    $obj->{'name'} = $self->name();
    $obj->{'admin'} = $self->admin();

    $obj->{'users'} = ();
    #$obj->{'external_id'} = $self->external_id();
    #$obj->{'max_circuits'} = $self->max_circuits();
    
#    foreach my $user (@{$self->users()}){
#        push(@{$self->{'users'}}, $user->to_hash());
#    }

    return $obj;
}

sub _fetch_from_db{
    my $self = shift;

    my $wg = OESS::DB::Workgroup::fetch(db => $self->{'db'}, workgroup_id => $self->{'workgroup_id'});
    $self->from_hash($wg);
    
}

sub workgroup_id{
    my $self = shift;
    my $workgroup_id = shift;

    if(!defined($workgroup_id)){
        return $self->{'workgroup_id'};
    }else{
        $self->{'workgroup_id'} = $workgroup_id;
        return $self->{'workgroup_id'};
    }
}

sub name{
    my $self = shift;
    my $name = shift;

    if(!defined($name)){
        return $self->{'name'};
    }else{
        $self->{'name'} = $name;
        return $self->{'name'};
    }
}

sub admin{
    my $self = shift;
    my $admin = shift;

    if(!defined($admin)){
        return $self->{'admin'};
    }else{
        $self->{'admin'} = $admin;
        return $self->{'admin'};
    }
}

sub users{
    my $self = shift;

    return [];
}

1;