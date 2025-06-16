#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use LogDashboard::Parser;

# Test the log parsing functionality
sub test_apache_log_parsing {
    my $parser = LogDashboard::Parser->new();
    
    # Sample Apache log line
    my $apache_line = '192.168.1.100 - - [25/Dec/2023:10:00:00 +0000] "GET /index.html HTTP/1.1" 200 1234 "-" "Mozilla/5.0" 1500';
    
    my $parsed = $parser->parse_apache_log($apache_line);
    
    ok($parsed, 'Apache log line parsed successfully');
    is($parsed->{ip_address}, '192.168.1.100', 'IP address extracted correctly');
    is($parsed->{method}, 'GET', 'HTTP method extracted correctly');
    is($parsed->{path}, '/index.html', 'Path extracted correctly');
    is($parsed->{status_code}, 200, 'Status code extracted correctly');
    is($parsed->{response_size}, 1234, 'Response size extracted correctly');
    is($parsed->{response_time}, 1.5, 'Response time converted to milliseconds');
}

sub test_nginx_log_parsing {
    my $parser = LogDashboard::Parser->new();
    
    # Sample Nginx log line
    my $nginx_line = '10.0.0.50 - - [2023-12-25 10:00:00] "POST /api/users HTTP/1.1" 201 567 "-" "curl/7.68.0" 0.250';
    
    my $parsed = $parser->parse_nginx_log($nginx_line);
    
    ok($parsed, 'Nginx log line parsed successfully');
    is($parsed->{ip_address}, '10.0.0.50', 'IP address extracted correctly');
    is($parsed->{method}, 'POST', 'HTTP method extracted correctly');
    is($parsed->{path}, '/api/users', 'Path extracted correctly');
    is($parsed->{status_code}, 201, 'Status code extracted correctly');
    is($parsed->{response_size}, 567, 'Response size extracted correctly');
    is($parsed->{response_time}, 250, 'Response time converted to milliseconds');
}

sub test_error_log_parsing {
    my $parser = LogDashboard::Parser->new();
    
    # Sample error log line
    my $error_line = '[2023-12-25 10:00:00] [error] File not found, client: 192.168.1.100, request: "GET /missing.html HTTP/1.1"';
    
    my $parsed = $parser->parse_error_log($error_line);
    
    ok($parsed, 'Error log line parsed successfully');
    is($parsed->{level}, 'ERROR', 'Error level extracted correctly');
    is($parsed->{ip_address}, '192.168.1.100', 'IP address extracted from error message');
    is($parsed->{path}, '/missing.html', 'Path extracted from error message');
    like($parsed->{message}, qr/File not found/, 'Error message extracted correctly');
}

sub test_auto_detection {
    my $parser = LogDashboard::Parser->new();
    
    # Test auto-detection of different log formats
    my $apache_line = '192.168.1.100 - - [25/Dec/2023:10:00:00 +0000] "GET /test HTTP/1.1" 200 100 "-" "Test"';
    my $error_line = '[2023-12-25 10:00:00] [warn] Test warning message';
    
    my $apache_parsed = $parser->parse_log_line($apache_line);
    my $error_parsed = $parser->parse_log_line($error_line);
    
    ok($apache_parsed, 'Apache format auto-detected');
    is($apache_parsed->{log_type}, 'access', 'Apache log type set correctly');
    
    ok($error_parsed, 'Error format auto-detected');
    is($error_parsed->{log_type}, 'error', 'Error log type set correctly');
}

# Run all tests
test_apache_log_parsing();
test_nginx_log_parsing();
test_error_log_parsing();
test_auto_detection();

done_testing(); 