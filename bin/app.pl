#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Plack::Builder;
use Plack::Request;
use HTML::Mason::PSGIHandler;

# Dependency Injection Container
use LogDashboard::Infrastructure::Database::DatabaseConnection;
use LogDashboard::Infrastructure::Repository::PostgreSQLLogEntryRepository;
use LogDashboard::Application::UseCase::GetDashboardStats;
use LogDashboard::Application::UseCase::GetRecentLogs;
use LogDashboard::Application::UseCase::GetErrorTrends;
use LogDashboard::Presentation::Controller::DashboardController;

# Application Bootstrap - Dependency Injection Setup
sub create_application {
    # Infrastructure Layer - Database Connection
    my $db_connection = LogDashboard::Infrastructure::Database::DatabaseConnection->new();
    my $dbh = $db_connection->get_connection();
    
    # Infrastructure Layer - Repository
    my $log_repository = LogDashboard::Infrastructure::Repository::PostgreSQLLogEntryRepository->new($dbh);
    
    # Application Layer - Use Cases
    my $get_dashboard_stats_use_case = LogDashboard::Application::UseCase::GetDashboardStats->new($log_repository);
    my $get_recent_logs_use_case = LogDashboard::Application::UseCase::GetRecentLogs->new($log_repository);
    my $get_error_trends_use_case = LogDashboard::Application::UseCase::GetErrorTrends->new($log_repository);
    
    # Presentation Layer - Controller
    my $dashboard_controller = LogDashboard::Presentation::Controller::DashboardController->new(
        get_dashboard_stats_use_case => $get_dashboard_stats_use_case,
        get_recent_logs_use_case => $get_recent_logs_use_case,
        get_error_trends_use_case => $get_error_trends_use_case,
    );
    
    return {
        dashboard_controller => $dashboard_controller,
        db_connection => $db_connection,
    };
}

# Initialize application dependencies
my $app_container = create_application();

# Mason handler setup (Presentation Layer)
my $mason = HTML::Mason::PSGIHandler->new(
    comp_root => "$Bin/../mason",
    data_dir  => "/tmp/mason_data",
);

# Main PSGI application - Entry Point
my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $path = $req->path_info;
    
    # API Routes - Delegate to Controller
    if ($path eq '/api/stats') {
        return $app_container->{dashboard_controller}->handle_stats_request($req);
    }
    elsif ($path eq '/api/recent-logs') {
        return $app_container->{dashboard_controller}->handle_recent_logs_request($req);
    }
    elsif ($path eq '/api/error-trends') {
        return $app_container->{dashboard_controller}->handle_error_trends_request($req);
    }
    elsif ($path eq '/api/health') {
        return $app_container->{dashboard_controller}->handle_health_check($req);
    }
    
    # Handle root path - redirect to index.mc
    if ($path eq '/') {
        $path = '/index.mc';
        $env->{PATH_INFO} = $path;
    }
    
    # Handle Mason templates (Presentation Layer)
    my $response = $mason->handle_psgi($env);
    
    # Ensure UTF-8 encoding for HTML responses
    if ($response->[1] && grep { /text\/html/ } @{$response->[1]}) {
        my $headers = $response->[1];
        for (my $i = 0; $i < @$headers; $i += 2) {
            if (lc($headers->[$i]) eq 'content-type' && $headers->[$i+1] !~ /charset/) {
                $headers->[$i+1] .= '; charset=utf-8';
                last;
            }
        }
    }
    
    return $response;
};

# Build the application with middleware (Infrastructure Layer)
builder {
    enable "Static",
        path => qr{^/(css|js|images)/},
        root => "$Bin/../public/";
    
    $app;
}; 