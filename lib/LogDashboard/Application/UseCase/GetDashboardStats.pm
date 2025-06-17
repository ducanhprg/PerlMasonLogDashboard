package LogDashboard::Application::UseCase::GetDashboardStats;

use strict;
use warnings;

# Use Case - encapsulates business logic for dashboard statistics

sub new {
    my ($class, $log_repository) = @_;
    
    die "Log repository required" unless $log_repository;
    
    my $self = {
        log_repository => $log_repository,
    };
    
    return bless $self, $class;
}

sub execute {
    my $self = shift;
    
    # Orchestrate multiple repository calls to build complete dashboard stats
    my $stats = {};
    
    # Get basic counts
    $stats->{total_requests} = $self->{log_repository}->count_all();
    $stats->{error_count} = $self->{log_repository}->count_errors();
    
    # Calculate error rate (business logic)
    $stats->{error_rate} = $self->_calculate_error_rate(
        $stats->{total_requests}, 
        $stats->{error_count}
    );
    
    # Get average response time
    $stats->{avg_response_time} = $self->{log_repository}->get_average_response_time();
    
    # Get top IPs
    $stats->{top_ips} = $self->{log_repository}->get_top_ips(5);
    
    # Get status code distribution
    $stats->{status_codes} = $self->{log_repository}->get_status_code_distribution();
    
    # Add computed fields
    $stats->{status} = $self->_determine_system_status($stats);
    $stats->{health_score} = $self->_calculate_health_score($stats);
    
    return $stats;
}

# Private business logic methods
sub _calculate_error_rate {
    my ($self, $total_requests, $error_count) = @_;
    
    return 0 unless $total_requests && $total_requests > 0;
    return sprintf("%.2f", ($error_count / $total_requests) * 100);
}

sub _determine_system_status {
    my ($self, $stats) = @_;
    
    my $error_rate = $stats->{error_rate} || 0;
    my $avg_response_time = $stats->{avg_response_time} || 0;
    
    # Business rules for system status
    return 'CRITICAL' if $error_rate > 10;
    return 'WARNING' if $error_rate > 5 || $avg_response_time > 2000;
    return 'HEALTHY';
}

sub _calculate_health_score {
    my ($self, $stats) = @_;
    
    my $error_rate = $stats->{error_rate} || 0;
    my $avg_response_time = $stats->{avg_response_time} || 0;
    
    # Simple health scoring algorithm (business logic)
    my $score = 100;
    
    # Penalize for high error rate
    $score -= $error_rate * 2;
    
    # Penalize for slow response times
    if ($avg_response_time > 1000) {
        $score -= ($avg_response_time - 1000) / 100;
    }
    
    # Ensure score stays within bounds
    $score = 0 if $score < 0;
    $score = 100 if $score > 100;
    
    return sprintf("%.1f", $score);
}

1; 