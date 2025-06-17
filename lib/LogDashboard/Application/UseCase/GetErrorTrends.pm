package LogDashboard::Application::UseCase::GetErrorTrends;

use strict;
use warnings;

# Use Case - encapsulates business logic for error trend analysis

sub new {
    my ($class, $log_repository) = @_;
    
    die "Log repository required" unless $log_repository;
    
    my $self = {
        log_repository => $log_repository,
    };
    
    return bless $self, $class;
}

sub execute {
    my ($self, $hours) = @_;
    
    # Validate input (business rules)
    $hours = $self->_validate_hours($hours);
    
    # Get raw trends from repository
    my $raw_trends = $self->{log_repository}->get_error_trends($hours);
    
    # Process and enrich the data (business logic)
    my $processed_trends = $self->_process_trends($raw_trends);
    
    return {
        trends => $processed_trends,
        period_hours => $hours,
        summary => $self->_generate_summary($processed_trends),
    };
}

# Private methods (business rules)
sub _validate_hours {
    my ($self, $hours) = @_;
    
    $hours ||= 24;
    $hours = int($hours);
    
    # Business rule: limit time range for performance
    return 1 if $hours < 1;
    return 168 if $hours > 168; # Max 1 week
    return $hours;
}

sub _process_trends {
    my ($self, $raw_trends) = @_;
    
    my @processed = ();
    
    for my $trend (@$raw_trends) {
        my $processed_trend = {
            hour => $trend->{hour},
            total_requests => $trend->{total_requests} || 0,
            errors => $trend->{errors} || 0,
            error_rate => $self->_calculate_error_rate(
                $trend->{total_requests}, 
                $trend->{errors}
            ),
            severity => $self->_determine_severity($trend->{errors}),
        };
        
        push @processed, $processed_trend;
    }
    
    return \@processed;
}

sub _calculate_error_rate {
    my ($self, $total, $errors) = @_;
    
    return 0 unless $total && $total > 0;
    return sprintf("%.2f", ($errors / $total) * 100);
}

sub _determine_severity {
    my ($self, $error_count) = @_;
    
    # Business rules for error severity
    return 'CRITICAL' if $error_count > 50;
    return 'HIGH' if $error_count > 20;
    return 'MEDIUM' if $error_count > 5;
    return 'LOW';
}

sub _generate_summary {
    my ($self, $trends) = @_;
    
    return {} unless @$trends;
    
    my $total_requests = 0;
    my $total_errors = 0;
    my $peak_errors = 0;
    my $peak_hour = '';
    
    for my $trend (@$trends) {
        $total_requests += $trend->{total_requests};
        $total_errors += $trend->{errors};
        
        if ($trend->{errors} > $peak_errors) {
            $peak_errors = $trend->{errors};
            $peak_hour = $trend->{hour};
        }
    }
    
    return {
        total_requests => $total_requests,
        total_errors => $total_errors,
        overall_error_rate => $self->_calculate_error_rate($total_requests, $total_errors),
        peak_errors => $peak_errors,
        peak_hour => $peak_hour,
        trend_direction => $self->_analyze_trend_direction($trends),
    };
}

sub _analyze_trend_direction {
    my ($self, $trends) = @_;
    
    return 'STABLE' unless @$trends >= 2;
    
    # Simple trend analysis: compare first half vs second half
    my $mid_point = int(@$trends / 2);
    my $first_half_avg = 0;
    my $second_half_avg = 0;
    
    # Calculate averages
    for my $i (0 .. $mid_point - 1) {
        $first_half_avg += $trends->[$i]->{errors};
    }
    $first_half_avg /= $mid_point if $mid_point > 0;
    
    for my $i ($mid_point .. @$trends - 1) {
        $second_half_avg += $trends->[$i]->{errors};
    }
    $second_half_avg /= (@$trends - $mid_point) if (@$trends - $mid_point) > 0;
    
    # Determine trend
    my $change_percent = $first_half_avg > 0 ? 
        (($second_half_avg - $first_half_avg) / $first_half_avg) * 100 : 0;
    
    return 'IMPROVING' if $change_percent < -10;
    return 'WORSENING' if $change_percent > 10;
    return 'STABLE';
}

1; 