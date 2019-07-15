#!/usr/bin/perl

use strict;
use warnings;

use OESS::Workgroup;

package OESS::DB::User;

=head2 fetch

=cut
sub fetch{
    my %params = @_;
    my $db = $params{'db'};
    my $user_id = $params{'user_id'};
    my $username = $params{'username'};

    my $user;

    if (defined $user_id) {
        my $q = "
            select remote_auth.auth_name as username, user.*
            from user
            join remote_auth on remote_auth.user_id=user.user_id
            where user.user_id = ?
        ";
        $user = $db->execute_query($q, [$user_id]);
    } else {
        my $q = "
            select remote_auth.auth_name as username, user.*
            from user
            join remote_auth on remote_auth.user_id=user.user_id
            where remote_auth.auth_name = ?
        ";
        $user = $db->execute_query($q, [$username]);
    }

    if(!defined($user) || !defined($user->[0])){
        return;
    }

    return $user->[0];
}

=head2 get_workgroups

=cut
sub get_workgroups {
    my $args = {
        db       => undef,
        user_id  => undef,
        @_
    };

    my $check = $args->{db}->execute_query(
        "SELECT is_admin from user where user_id=?",
        [$args->{user_id}]
    );
    if (!defined $check && !defined $check->[0]) {
        return (undef, $args->{db}->get_error);
    }

    my $query;
    my $values;
    if ($check->[0]->{is_admin}) {
        $query = "SELECT * from workgroup";
        $values = [];
    } else {
        $query = "
            SELECT workgroup.*
            FROM workgroup
            JOIN user_workgroup_membership ON workgroup.workgroup_id=user_workgroup_membership.workgroup_id
            WHERE user_workgroup_membership.user_id=?
        ";
        $values = [$args->{user_id}];
    }

    my $datas = $args->{db}->execute_query($query, $values);
    if (!defined $datas) {
        return (undef, $args->{db}->get_error);
    }

    return ($datas, undef);
}

=head2 find_user_by_remote_auth
=cut
sub find_user_by_remote_auth{
    my %params = @_;
    my $db = $params{'db'};
    my $remote_user = $params{'remote_user'};

    my $user_id = $db->execute_query("select remote_auth.user_id from remote_auth where remote_auth.auth_name = ?",[$remote_user]);
    if(!defined($user_id) || !defined($user_id->[0])){
        return;
    }

    return $user_id->[0];
}

1;
