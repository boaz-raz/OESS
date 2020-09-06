#!/usr/bin/perl

use strict;
use warnings;

package OESS::User;

use Data::Dumper;

use OESS::DB::User;
use OESS::Workgroup;

=head2 new

=cut
sub new{
    my $that  = shift;
    my $class = ref($that) || $that;

    my $self = {
        user_id => undef,
        db => undef,
        model => undef,
        logger => Log::Log4perl->get_logger("OESS.User"),
        @_
    };
    bless $self, $class;

    if (defined $self->{db} && (defined $self->{user_id} || defined $self->{username})) {
        $self->{model} = OESS::DB::User::fetch(
            db       => $self->{db},
            user_id  => $self->{user_id},
            username => $self->{username}
        );
    }

    if (!defined $self->{model}) {
        return;
    }

    $self->from_hash($self->{model});
    return $self;
}

=head2 to_hash

=cut
sub to_hash{
    my $self = shift;

    my $obj = {};

    $obj->{'username'} = $self->username();
    $obj->{'first_name'} = $self->first_name();
    $obj->{'last_name'} = $self->last_name();
    $obj->{'email'} = $self->email();
    $obj->{'user_id'} = $self->user_id();
    $obj->{'is_admin'} = $self->is_admin();

    if (defined $self->{workgroups}) {
        $obj->{'workgroups'} = [];
        foreach my $wg (@{$self->{workgroups}}) {
            push @{$obj->{workgroups}}, $wg->to_hash;
        }
    }
    if (defined $self->{'role'}) {
        $obj->{role} = $self->role();
    }
    return $obj;
}

=head2 from_hash

=cut
sub from_hash{
    my $self = shift;
    my $hash = shift;

    $self->{email}      = $hash->{email};
    $self->{first_name} = $hash->{first_names};
    $self->{last_name}  = $hash->{last_name};
    $self->{user_id}    = $hash->{user_id};
    $self->{username}   = $hash->{username};

    if (defined $hash->{workgroups}) {
        $self->{workgroups} = $hash->{workgroups};
    }
    return 1;
}

=head2 create

=cut
sub create {
    my $self = shift;

    if (!defined $self->{db}) {
        return (undef, "Couldn't create User. Database handle is missing.");
    }

    my ($id, $err) = OESS::DB::User::add_user(
        db          => $self->{db},
        email       => $self->{model}->{email},
        family_name => $self->{model}->{last_name},
        given_name  => $self->{model}->{first_name},
        auth_names  => $self->{model}->{username}
    );
    if (defined $err) {
        return (undef, $err);
    }

    $self->{user_id} = $id;
    return ($id, undef);
}

=head2 load_workgroups

=cut
sub load_workgroups {
    my $self = shift;

    my ($datas, $err) = OESS::DB::User::get_workgroups(
        db => $self->{db},
        user_id => $self->{user_id}
    );
    if (defined $err) {
        $self->{logger}->error($err);
        return;
    }

    $self->{workgroups} = [];
    foreach my $data (@$datas){
        push @{$self->{workgroups}}, OESS::Workgroup->new(db => $self->{db}, model => $data);
    }

    return;
}

=head2 get_workgroup

    my $wg = $user->get_workgroup(
        workgroup_id => 100
    );

get_workgroup returns the Workgroup identified by C<workgroup_id>.

=cut
sub get_workgroup {
    my $self = shift;
    my $args = {
        workgroup_id => undef,
        @_
    };

    if (!defined $args->{workgroup_id}) {
        return;
    }

    foreach my $workgroup (@{$self->{workgroups}}) {
        if ($workgroup->workgroup_id == $args->{workgroup_id}) {
            return $workgroup;
        }
    }

    return;
}

=head2 username

=cut
sub username{
    my $self = shift;
    return $self->{'username'};
}

=head2 first_name

=cut
sub first_name{
    my $self = shift;
    return $self->{'first_name'};
}

=head2 last_name

=cut
sub last_name{
    my $self = shift;
    return $self->{'last_name'};

}

=head2 user_id

=cut
sub user_id{
    my $self = shift;
    return $self->{'user_id'};
    
}

=head2 workgroups

=cut
sub workgroups{
    my $self = shift;
    return $self->{'workgroups'} || [];
}

=head2 role

=cut
sub role{
    my $self = shift;
    return $self->{role};
}

=head2 email

=cut
sub email{
    my $self = shift;
    return $self->{'email'};
}

=head2 is_admin

=cut
sub is_admin{
    my $self = shift;
    return $self->{'is_admin'};
}

=head2 in_workgroup

=cut
sub in_workgroup{
    my $self = shift;
    my $workgroup_id = shift;

    $self->load_workgroups if !defined $self->{workgroups};

    foreach my $wg (@{$self->workgroups()}){
        if($wg->workgroup_id() == $workgroup_id){
            return 1;
        }
    }
    return 0;
}

=head2 has_workgroup_access

=cut
sub has_workgroup_access {
    my $self = shift;
    my $args = {
        role         => undef,
        workgroup_id => undef,
        @_
    };

    return OESS::DB::User::has_workgroup_access(
        db           => $self->{db},
        role         => $args->{role},
        username     => $self->{username},
        workgroup_id => $args->{workgroup_id}
    );
}

=head2 has_system_access

=cut
sub has_system_access {
    my $self = shift;
    my $args = {
        role => undef,
        @_
    };

    return OESS::DB::User::has_system_access(
        db       => $self->{db},
        role     => $args->{role},
        username => $self->{username}
    );
}

1;
