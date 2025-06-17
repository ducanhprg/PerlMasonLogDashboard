package LogDashboard::Infrastructure::Repository::PostgreSQLLogEntryRepository;

use strict;
use warnings;
# Remove parent inheritance - implement interface directly

use LogDashboard::Domain::Entity::LogEntry;
use DBI;
use DateTime;

# Concrete Repository Implementation for PostgreSQL
# Follows DDD principles: encapsulation, single responsibility

sub new {
    my ($class, $dbh) = @_;
    die "Database handle required" unless $dbh;
    
    my $self = {
        dbh => $dbh,
    };
    
    return bless $self, $class;
}

sub find_by_id {
    my ($self, $id) = @_;
    
    my $sql = q{
        SELECT id, log_type, ip_address, timestamp, method, path, 
               status_code, response_size, user_agent, response_time,
               level, message, created_at
        FROM log_entries 
        WHERE id = ?
    };
    
    my $row = $self->{dbh}->selectrow_hashref($sql, {}, $id);
    return $row ? $self->_build_entity($row) : undef;
}

sub find_all {
    my ($self, %options) = @_;
    
    my $sql = q{
        SELECT id, log_type, ip_address, timestamp, method, path, 
               status_code, response_size, user_agent, response_time,
               level, message, created_at
        FROM log_entries 
        ORDER BY timestamp DESC
    };
    
    if ($options{limit}) {
        $sql .= " LIMIT $options{limit}";
    }
    
    my $rows = $self->{dbh}->selectall_arrayref($sql, { Slice => {} });
    return [map { $self->_build_entity($_) } @$rows];
}

sub find_paginated {
    my ($self, $page, $limit, %filters) = @_;
    
    $page ||= 1;
    $limit ||= 10;
    my $offset = ($page - 1) * $limit;
    
    # Build WHERE clause from filters
    my @where_conditions;
    my @bind_params;
    
    if ($filters{log_type}) {
        push @where_conditions, "log_type = ?";
        push @bind_params, $filters{log_type};
    }
    
    if ($filters{ip_address}) {
        push @where_conditions, "ip_address = ?";
        push @bind_params, $filters{ip_address};
    }
    
    if ($filters{status_code}) {
        push @where_conditions, "status_code = ?";
        push @bind_params, $filters{status_code};
    }
    
    my $where_clause = @where_conditions ? 
        "WHERE " . join(" AND ", @where_conditions) : "";
    
    # Get total count
    my $count_sql = "SELECT COUNT(*) FROM log_entries $where_clause";
    my ($total_count) = $self->{dbh}->selectrow_array($count_sql, {}, @bind_params);
    
    # Get paginated results
    my $sql = qq{
        SELECT id, log_type, ip_address, timestamp, method, path, 
               status_code, response_size, user_agent, response_time,
               level, message, created_at
        FROM log_entries 
        $where_clause
        ORDER BY timestamp DESC 
        LIMIT ? OFFSET ?
    };
    
    push @bind_params, $limit, $offset;
    my $rows = $self->{dbh}->selectall_arrayref($sql, { Slice => {} }, @bind_params);
    
    my $total_pages = int(($total_count + $limit - 1) / $limit);
    
    return {
        entries => [map { $self->_build_entity($_) } @$rows],
        pagination => {
            current_page => $page,
            total_pages => $total_pages,
            total_count => $total_count,
            limit => $limit,
            has_next => $page < $total_pages,
            has_prev => $page > 1,
        }
    };
}

sub find_by_ip_address {
    my ($self, $ip_address) = @_;
    
    my $sql = q{
        SELECT id, log_type, ip_address, timestamp, method, path, 
               status_code, response_size, user_agent, response_time,
               level, message, created_at
        FROM log_entries 
        WHERE ip_address = ?
        ORDER BY timestamp DESC
    };
    
    my $rows = $self->{dbh}->selectall_arrayref($sql, { Slice => {} }, $ip_address);
    return [map { $self->_build_entity($_) } @$rows];
}

sub find_errors_by_time_range {
    my ($self, $start_time, $end_time) = @_;
    
    my $sql = q{
        SELECT id, log_type, ip_address, timestamp, method, path, 
               status_code, response_size, user_agent, response_time,
               level, message, created_at
        FROM log_entries 
        WHERE (log_type = 'error' OR status_code >= 400)
          AND timestamp BETWEEN ? AND ?
        ORDER BY timestamp DESC
    };
    
    my $rows = $self->{dbh}->selectall_arrayref($sql, { Slice => {} }, $start_time, $end_time);
    return [map { $self->_build_entity($_) } @$rows];
}

sub save {
    my ($self, $log_entry) = @_;
    
    die "LogEntry entity required" unless ref($log_entry) eq 'LogDashboard::Domain::Entity::LogEntry';
    
    my $sql = q{
        INSERT INTO log_entries (
            log_type, ip_address, timestamp, method, path, 
            status_code, response_size, user_agent, response_time,
            level, message
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        RETURNING id
    };
    
    my ($id) = $self->{dbh}->selectrow_array($sql, {},
        $log_entry->log_type,
        $log_entry->ip_address,
        $log_entry->timestamp,
        $log_entry->method,
        $log_entry->path,
        $log_entry->status_code,
        $log_entry->response_size,
        $log_entry->user_agent,
        $log_entry->response_time,
        $log_entry->level,
        $log_entry->message
    );
    
    return $id;
}

sub delete {
    my ($self, $id) = @_;
    
    my $sql = "DELETE FROM log_entries WHERE id = ?";
    my $rows_affected = $self->{dbh}->do($sql, {}, $id);
    
    return $rows_affected > 0;
}

# Aggregate Methods
sub count_all {
    my $self = shift;
    
    my ($count) = $self->{dbh}->selectrow_array(
        "SELECT COUNT(*) FROM log_entries WHERE log_type = 'access'"
    );
    
    return $count || 0;
}

sub count_errors {
    my ($self, %filters) = @_;
    
    my $sql = "SELECT COUNT(*) FROM log_entries WHERE status_code >= 400";
    my @bind_params;
    
    if ($filters{hours}) {
        # Fix: PostgreSQL doesn't support parameterized INTERVAL
        my $hours = int($filters{hours}); # Sanitize input
        $sql .= " AND timestamp >= NOW() - INTERVAL '$hours hours'";
        # No bind parameter needed for INTERVAL
    }
    
    my ($count) = $self->{dbh}->selectrow_array($sql, {}, @bind_params);
    return $count || 0;
}

sub get_top_ips {
    my ($self, $limit) = @_;
    $limit ||= 5;
    
    my $sql = q{
        SELECT ip_address, COUNT(*) as count 
        FROM log_entries 
        GROUP BY ip_address 
        ORDER BY count DESC 
        LIMIT ?
    };
    
    return $self->{dbh}->selectall_arrayref($sql, { Slice => {} }, $limit);
}

sub get_status_code_distribution {
    my $self = shift;
    
    my $sql = q{
        SELECT status_code, COUNT(*) as count 
        FROM log_entries 
        WHERE status_code IS NOT NULL
        GROUP BY status_code 
        ORDER BY count DESC
    };
    
    return $self->{dbh}->selectall_arrayref($sql, { Slice => {} });
}

sub get_error_trends {
    my ($self, $hours) = @_;
    $hours ||= 24;
    
    # Fix: PostgreSQL doesn't support parameterized INTERVAL
    my $safe_hours = int($hours); # Sanitize input
    my $sql = qq{
        SELECT DATE_TRUNC('hour', timestamp) as hour,
               COUNT(*) as total_requests,
               COUNT(CASE WHEN status_code >= 400 THEN 1 END) as errors
        FROM log_entries 
        WHERE timestamp >= NOW() - INTERVAL '$safe_hours hours'
        GROUP BY hour
        ORDER BY hour
    };
    
    return $self->{dbh}->selectall_arrayref($sql, { Slice => {} });
}

sub get_average_response_time {
    my $self = shift;
    
    my ($avg) = $self->{dbh}->selectrow_array(
        "SELECT AVG(response_time) FROM log_entries WHERE response_time IS NOT NULL"
    );
    
    return $avg ? sprintf("%.2f", $avg) : 0;
}

# Private method to build entity from database row
sub _build_entity {
    my ($self, $row) = @_;
    
    return LogDashboard::Domain::Entity::LogEntry->new(
        id => $row->{id},
        log_type => $row->{log_type},
        ip_address => $row->{ip_address},
        timestamp => $row->{timestamp},
        method => $row->{method},
        path => $row->{path},
        status_code => $row->{status_code},
        response_size => $row->{response_size},
        user_agent => $row->{user_agent},
        response_time => $row->{response_time},
        level => $row->{level},
        message => $row->{message},
        created_at => $row->{created_at},
    );
}

1; 