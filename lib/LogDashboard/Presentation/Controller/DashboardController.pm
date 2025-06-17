package LogDashboard::Presentation::Controller::DashboardController;

use strict;
use warnings;
use JSON::XS;
use Plack::Request;
use Plack::Response;

# Controller - handles HTTP requests and responses

sub new {
    my ($class, %dependencies) = @_;
    
    # Dependency injection
    die "get_dashboard_stats_use_case required" unless $dependencies{get_dashboard_stats_use_case};
    die "get_recent_logs_use_case required" unless $dependencies{get_recent_logs_use_case};
    die "get_error_trends_use_case required" unless $dependencies{get_error_trends_use_case};
    
    my $self = {
        get_dashboard_stats_use_case => $dependencies{get_dashboard_stats_use_case},
        get_recent_logs_use_case => $dependencies{get_recent_logs_use_case},
        get_error_trends_use_case => $dependencies{get_error_trends_use_case},
        json => JSON::XS->new->utf8,
    };
    
    return bless $self, $class;
}

sub handle_stats_request {
    my ($self, $req) = @_;
    
    my $response;
    eval {
        # Delegate to use case
        my $stats = $self->{get_dashboard_stats_use_case}->execute();
        
        # Return JSON response
        $response = $self->_json_response(200, $stats);
    };
    
    if ($@) {
        $response = $self->_error_response(500, "Failed to get dashboard stats: $@");
    }
    
    return $response;
}

sub handle_recent_logs_request {
    my ($self, $req) = @_;
    
    my $response;
    eval {
        # Extract parameters from request
        my $page = $req->param('page') || 1;
        my $limit = $req->param('limit') || 10;
        
        # Extract filters
        my %filters = ();
        $filters{log_type} = $req->param('log_type') if $req->param('log_type');
        $filters{ip_address} = $req->param('ip_address') if $req->param('ip_address');
        $filters{status_code} = $req->param('status_code') if $req->param('status_code');
        $filters{method} = $req->param('method') if $req->param('method');
        
        # Delegate to use case
        my $result = $self->{get_recent_logs_use_case}->execute($page, $limit, %filters);
        
        # Return JSON response
        $response = $self->_json_response(200, $result);
    };
    
    if ($@) {
        $response = $self->_error_response(500, "Failed to get recent logs: $@");
    }
    
    return $response;
}

sub handle_error_trends_request {
    my ($self, $req) = @_;
    
    my $response;
    eval {
        # Extract parameters
        my $hours = $req->param('hours') || 24;
        
        # Delegate to use case
        my $trends = $self->{get_error_trends_use_case}->execute($hours);
        
        # Return JSON response
        $response = $self->_json_response(200, $trends);
    };
    
    if ($@) {
        $response = $self->_error_response(500, "Failed to get error trends: $@");
    }
    
    return $response;
}

sub handle_health_check {
    my ($self, $req) = @_;
    
    # Simple health check endpoint
    return $self->_json_response(200, {
        status => 'OK',
        timestamp => time(),
        service => 'LogDashboard API'
    });
}

# Private helper methods
sub _json_response {
    my ($self, $status, $data) = @_;
    
    my $res = Plack::Response->new($status);
    $res->content_type('application/json; charset=utf-8');
    $res->body($self->{json}->encode($data));
    
    return $res->finalize;
}

sub _error_response {
    my ($self, $status, $message) = @_;
    
    my $error_data = {
        error => {
            code => $status,
            message => $message,
            timestamp => time(),
        }
    };
    
    return $self->_json_response($status, $error_data);
}

1; 