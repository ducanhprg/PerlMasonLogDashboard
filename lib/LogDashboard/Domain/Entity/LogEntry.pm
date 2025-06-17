package LogDashboard::Domain::Entity::LogEntry;

use strict;
use warnings;
use DateTime;

# Domain Entity - represents a log entry with business rules
# Follows DDD principles: identity, encapsulation, business invariants

sub new {
    my ($class, %args) = @_;
    
    # Validate required fields (business invariants)
    die "LogEntry requires id" unless $args{id};
    die "LogEntry requires log_type" unless $args{log_type};
    die "Invalid log_type: must be 'access' or 'error'" 
        unless $args{log_type} =~ /^(access|error)$/;
    
    my $self = {
        id => $args{id},
        log_type => $args{log_type},
        ip_address => $args{ip_address},
        timestamp => $args{timestamp},
        method => $args{method},
        path => $args{path},
        status_code => $args{status_code},
        response_size => $args{response_size},
        user_agent => $args{user_agent},
        response_time => $args{response_time},
        level => $args{level},
        message => $args{message},
        created_at => $args{created_at} || DateTime->now(),
    };
    
    return bless $self, $class;
}

# Getters (immutable after creation)
sub id { $_[0]->{id} }
sub log_type { $_[0]->{log_type} }
sub ip_address { $_[0]->{ip_address} }
sub timestamp { $_[0]->{timestamp} }
sub method { $_[0]->{method} }
sub path { $_[0]->{path} }
sub status_code { $_[0]->{status_code} }
sub response_size { $_[0]->{response_size} }
sub user_agent { $_[0]->{user_agent} }
sub response_time { $_[0]->{response_time} }
sub level { $_[0]->{level} }
sub message { $_[0]->{message} }
sub created_at { $_[0]->{created_at} }

# Business Logic Methods (Domain Rules)
sub is_error {
    my $self = shift;
    return $self->log_type eq 'error' || 
           ($self->status_code && $self->status_code >= 400);
}

sub is_client_error {
    my $self = shift;
    return $self->status_code && $self->status_code >= 400 && $self->status_code < 500;
}

sub is_server_error {
    my $self = shift;
    return $self->status_code && $self->status_code >= 500;
}

sub is_slow_request {
    my $self = shift;
    my $threshold = shift || 1000; # 1 second default
    return $self->response_time && $self->response_time > $threshold;
}

sub get_severity_level {
    my $self = shift;
    
    return 'CRITICAL' if $self->is_server_error;
    return 'WARNING' if $self->is_client_error;
    return 'ERROR' if $self->log_type eq 'error';
    return 'INFO';
}

# Convert to hash for serialization
sub to_hash {
    my $self = shift;
    
    return {
        id => $self->id,
        log_type => $self->log_type,
        ip_address => $self->ip_address,
        timestamp => $self->timestamp,
        method => $self->method,
        path => $self->path,
        status_code => $self->status_code,
        response_size => $self->response_size,
        user_agent => $self->user_agent,
        response_time => $self->response_time,
        level => $self->level,
        message => $self->message,
        created_at => $self->created_at,
        # Computed properties
        is_error => $self->is_error,
        severity => $self->get_severity_level,
    };
}

1; 