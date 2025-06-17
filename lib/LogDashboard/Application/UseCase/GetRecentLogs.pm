package LogDashboard::Application::UseCase::GetRecentLogs;

use strict;
use warnings;

# Use Case - encapsulates business logic for retrieving recent logs

sub new {
    my ($class, $log_repository) = @_;
    
    die "Log repository required" unless $log_repository;
    
    my $self = {
        log_repository => $log_repository,
    };
    
    return bless $self, $class;
}

sub execute {
    my ($self, $page, $limit, %filters) = @_;
    
    # Validate and sanitize inputs (business rules)
    $page = $self->_validate_page($page);
    $limit = $self->_validate_limit($limit);
    %filters = $self->_sanitize_filters(%filters);
    
    # Get paginated results from repository
    my $result = $self->{log_repository}->find_paginated($page, $limit, %filters);
    
    # Transform entities to DTOs for presentation layer
    my @log_dtos = map { $self->_transform_to_dto($_) } @{$result->{entries}};
    
    return {
        logs => \@log_dtos,
        pagination => $result->{pagination},
        filters_applied => \%filters,
    };
}

# Private validation methods (business rules)
sub _validate_page {
    my ($self, $page) = @_;
    
    $page ||= 1;
    $page = int($page);
    return $page > 0 ? $page : 1;
}

sub _validate_limit {
    my ($self, $limit) = @_;
    
    $limit ||= 10;
    $limit = int($limit);
    
    # Business rule: limit pagination size
    return 5 if $limit < 5;
    return 100 if $limit > 100;
    return $limit;
}

sub _sanitize_filters {
    my ($self, %filters) = @_;
    
    my %clean_filters;
    
    # Only allow specific filter keys (security)
    my @allowed_filters = qw(log_type ip_address status_code method);
    
    for my $key (@allowed_filters) {
        if (exists $filters{$key} && defined $filters{$key} && $filters{$key} ne '') {
            $clean_filters{$key} = $filters{$key};
        }
    }
    
    # Validate log_type
    if ($clean_filters{log_type} && $clean_filters{log_type} !~ /^(access|error)$/) {
        delete $clean_filters{log_type};
    }
    
    # Validate status_code
    if ($clean_filters{status_code}) {
        my $status = int($clean_filters{status_code});
        if ($status < 100 || $status > 599) {
            delete $clean_filters{status_code};
        } else {
            $clean_filters{status_code} = $status;
        }
    }
    
    return %clean_filters;
}

sub _transform_to_dto {
    my ($self, $entity) = @_;
    
    # Transform domain entity to DTO for presentation layer
    # Add computed fields and format data
    my $dto = $entity->to_hash();
    
    # Add presentation-specific fields
    $dto->{formatted_timestamp} = $self->_format_timestamp($entity->timestamp);
    $dto->{status_class} = $self->_get_status_css_class($entity->status_code);
    $dto->{response_time_formatted} = $self->_format_response_time($entity->response_time);
    
    return $dto;
}

sub _format_timestamp {
    my ($self, $timestamp) = @_;
    
    return '' unless $timestamp;
    
    # Format timestamp for display
    if (ref($timestamp) eq 'DateTime') {
        return $timestamp->strftime('%Y-%m-%d %H:%M:%S');
    }
    
    return $timestamp;
}

sub _get_status_css_class {
    my ($self, $status_code) = @_;
    
    return '' unless $status_code;
    
    # Business rules for status code styling
    return 'success' if $status_code >= 200 && $status_code < 300;
    return 'info' if $status_code >= 300 && $status_code < 400;
    return 'warning' if $status_code >= 400 && $status_code < 500;
    return 'danger' if $status_code >= 500;
    return 'secondary';
}

sub _format_response_time {
    my ($self, $response_time) = @_;
    
    return 'N/A' unless defined $response_time;
    
    # Format response time with appropriate units
    if ($response_time < 1000) {
        return sprintf("%.0f ms", $response_time);
    } else {
        return sprintf("%.2f s", $response_time / 1000);
    }
}

1; 