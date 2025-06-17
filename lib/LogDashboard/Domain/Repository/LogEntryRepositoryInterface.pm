package LogDashboard::Domain::Repository::LogEntryRepositoryInterface;

use strict;
use warnings;

# Repository Interface - defines contract for data access
# Follows DDD principles: abstraction, dependency inversion

sub new {
    my $class = shift;
    return bless {}, $class;
}

# Abstract methods that must be implemented by concrete repositories
sub find_by_id {
    my ($self, $id) = @_;
    die "find_by_id must be implemented by concrete repository";
}

sub find_all {
    my ($self, %options) = @_;
    die "find_all must be implemented by concrete repository";
}

sub find_paginated {
    my ($self, $page, $limit, %filters) = @_;
    die "find_paginated must be implemented by concrete repository";
}

sub find_by_ip_address {
    my ($self, $ip_address) = @_;
    die "find_by_ip_address must be implemented by concrete repository";
}

sub find_errors_by_time_range {
    my ($self, $start_time, $end_time) = @_;
    die "find_errors_by_time_range must be implemented by concrete repository";
}

sub save {
    my ($self, $log_entry) = @_;
    die "save must be implemented by concrete repository";
}

sub delete {
    my ($self, $id) = @_;
    die "delete must be implemented by concrete repository";
}

# Aggregate queries
sub count_all {
    my $self = shift;
    die "count_all must be implemented by concrete repository";
}

sub count_errors {
    my ($self, %filters) = @_;
    die "count_errors must be implemented by concrete repository";
}

sub get_top_ips {
    my ($self, $limit) = @_;
    die "get_top_ips must be implemented by concrete repository";
}

sub get_status_code_distribution {
    my $self = shift;
    die "get_status_code_distribution must be implemented by concrete repository";
}

sub get_error_trends {
    my ($self, $hours) = @_;
    die "get_error_trends must be implemented by concrete repository";
}

sub get_average_response_time {
    my $self = shift;
    die "get_average_response_time must be implemented by concrete repository";
}

1; 