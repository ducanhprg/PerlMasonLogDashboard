#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Plack::Builder;
use Plack::Request;
use Plack::Response;
use HTML::Mason::PSGIHandler;
use DBI;
use JSON::XS;
use DateTime;

# Database connection
sub get_db_connection {
    my $dsn = sprintf("dbi:Pg:dbname=%s;host=%s;port=%s",
        $ENV{DB_NAME} || 'log_dashboard',
        $ENV{DB_HOST} || 'localhost', 
        $ENV{DB_PORT} || '5432'
    );
    
    return DBI->connect($dsn, 
        $ENV{DB_USER} || 'postgres',
        $ENV{DB_PASSWORD} || 'postgres',
        { RaiseError => 1, AutoCommit => 1, pg_enable_utf8 => 1 }
    );
}

# Mason handler setup
my $mason = HTML::Mason::PSGIHandler->new(
    comp_root => "$Bin/../mason",
    data_dir  => "/tmp/mason_data",
);

# Main PSGI application
my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $path = $req->path_info;
    
    # Handle API endpoints
    if ($path =~ m{^/api/}) {
        return handle_api($req);
    }
    
    # Handle root path - redirect to index.mc
    if ($path eq '/') {
        $path = '/index.mc';
        $env->{PATH_INFO} = $path;
    }
    
    # Handle Mason templates
    my $response = $mason->handle_psgi($env);
    
    # Ensure UTF-8 encoding for HTML responses
    if ($response->[1] && grep { /text\/html/ } @{$response->[1]}) {
        # Add UTF-8 charset if not already present
        my $headers = $response->[1];
        my $has_charset = 0;
        for (my $i = 0; $i < @$headers; $i += 2) {
            if (lc($headers->[$i]) eq 'content-type' && $headers->[$i+1] !~ /charset/) {
                $headers->[$i+1] .= '; charset=utf-8';
                $has_charset = 1;
                last;
            }
        }
    }
    
    return $response;
};

# API handler for dashboard data
sub handle_api {
    my $req = shift;
    my $res = Plack::Response->new(200);
    $res->content_type('application/json; charset=utf-8');
    
    my $dbh = get_db_connection();
    my $data = {};
    
    if ($req->path_info eq '/api/stats') {
        $data = get_dashboard_stats($dbh);
    } elsif ($req->path_info eq '/api/recent-logs') {
        my $page = $req->param('page') || 1;
        my $limit = $req->param('limit') || 10;
        $data = get_recent_logs($dbh, $page, $limit);
    } elsif ($req->path_info eq '/api/error-trends') {
        $data = get_error_trends($dbh);
    }
    
    $dbh->disconnect;
    $res->body(JSON::XS->new->utf8->encode($data));
    return $res->finalize;
}

# Get dashboard statistics - showcasing PostgreSQL aggregation
sub get_dashboard_stats {
    my $dbh = shift;
    
    my $stats = {};
    
    # Total requests
    my ($total_requests) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM log_entries WHERE log_type = 'access'"
    );
    $stats->{total_requests} = $total_requests || 0;
    
    # Error rate
    my ($error_count) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM log_entries WHERE status_code >= 400"
    );
    $stats->{error_rate} = $total_requests ? 
        sprintf("%.2f", ($error_count / $total_requests) * 100) : 0;
    
    # Average response time
    my ($avg_response_time) = $dbh->selectrow_array(
        "SELECT AVG(response_time) FROM log_entries WHERE response_time IS NOT NULL"
    );
    $stats->{avg_response_time} = $avg_response_time ? 
        sprintf("%.2f", $avg_response_time) : 0;
    
    # Top IPs
    my $top_ips = $dbh->selectall_arrayref(
        "SELECT ip_address, COUNT(*) as count 
         FROM log_entries 
         GROUP BY ip_address 
         ORDER BY count DESC 
         LIMIT 5",
        { Slice => {} }
    );
    $stats->{top_ips} = $top_ips;
    
    # Status code distribution
    my $status_codes = $dbh->selectall_arrayref(
        "SELECT status_code, COUNT(*) as count 
         FROM log_entries 
         WHERE status_code IS NOT NULL
         GROUP BY status_code 
         ORDER BY count DESC",
        { Slice => {} }
    );
    $stats->{status_codes} = $status_codes;
    
    return $stats;
}

# Get recent log entries
sub get_recent_logs {
    my ($dbh, $page, $limit) = @_;
    $page ||= 1;
    $limit ||= 10;
    
    my $offset = ($page - 1) * $limit;
    
    # Get total count for pagination
    my ($total_count) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM log_entries"
    );
    
    # Get paginated logs
    my $logs = $dbh->selectall_arrayref(
        "SELECT timestamp, ip_address, method, path, status_code, response_time, user_agent
         FROM log_entries 
         ORDER BY timestamp DESC 
         LIMIT ? OFFSET ?",
        { Slice => {} },
        $limit, $offset
    );
    
    my $total_pages = int(($total_count + $limit - 1) / $limit);
    
    return { 
        logs => $logs,
        pagination => {
            current_page => $page,
            total_pages => $total_pages,
            total_count => $total_count,
            limit => $limit,
            has_next => $page < $total_pages,
            has_prev => $page > 1
        }
    };
}

# Get error trends over time - showcasing PostgreSQL time-series analysis
sub get_error_trends {
    my $dbh = shift;
    
    my $trends = $dbh->selectall_arrayref(
        "SELECT DATE_TRUNC('hour', timestamp) as hour,
                COUNT(*) as total_requests,
                COUNT(CASE WHEN status_code >= 400 THEN 1 END) as errors
         FROM log_entries 
         WHERE timestamp >= NOW() - INTERVAL '24 hours'
         GROUP BY hour
         ORDER BY hour",
        { Slice => {} }
    );
    
    return { trends => $trends };
}

# Build the application with middleware
builder {
    enable "Static",
        path => qr{^/(css|js|images)/},
        root => "$Bin/../public/";
    
    $app;
}; 