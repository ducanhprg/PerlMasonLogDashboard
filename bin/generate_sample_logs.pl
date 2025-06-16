#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use DateTime;
use LogDashboard::Parser;
use DBI;

# Sample data for realistic log generation
my @ips = qw(
    192.168.1.100 10.0.0.50 203.0.113.45 198.51.100.23
    172.16.0.10 192.168.0.200 203.0.113.78 198.51.100.89
);

my @user_agents = (
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
    'curl/7.68.0',
    'Python-urllib/3.8',
);

my @paths = qw(
    / /index.html /about /contact /api/users /api/orders
    /login /logout /dashboard /admin /static/css/style.css
    /static/js/app.js /images/logo.png /favicon.ico
);

my @methods = qw(GET POST PUT DELETE);
my @status_codes = (200, 200, 200, 200, 301, 302, 404, 500, 503);

sub generate_apache_logs {
    my ($count, $output_file) = @_;
    
    open my $fh, '>', $output_file or die "Cannot open $output_file: $!";
    
    print "Generating $count Apache log entries...\n";
    
    for my $i (1..$count) {
        my $ip = $ips[rand @ips];
        my $timestamp = DateTime->now->subtract(minutes => rand(1440));
        my $method = $methods[rand @methods];
        my $path = $paths[rand @paths];
        my $status = $status_codes[rand @status_codes];
        my $size = int(rand(10000)) + 100;
        my $user_agent = $user_agents[rand @user_agents];
        my $response_time = int(rand(5000)) + 10; # microseconds
        
        my $log_line = sprintf(
            '%s - - [%s] "%s %s HTTP/1.1" %d %d "-" "%s" %d',
            $ip,
            $timestamp->strftime('%d/%b/%Y:%H:%M:%S %z'),
            $method,
            $path,
            $status,
            $size,
            $user_agent,
            $response_time
        );
        
        print $fh "$log_line\n";
    }
    
    close $fh;
    print "Apache logs written to $output_file\n";
}

sub generate_nginx_logs {
    my ($count, $output_file) = @_;
    
    open my $fh, '>', $output_file or die "Cannot open $output_file: $!";
    
    print "Generating $count Nginx log entries...\n";
    
    for my $i (1..$count) {
        my $ip = $ips[rand @ips];
        my $timestamp = DateTime->now->subtract(minutes => rand(1440));
        my $method = $methods[rand @methods];
        my $path = $paths[rand @paths];
        my $status = $status_codes[rand @status_codes];
        my $size = int(rand(10000)) + 100;
        my $user_agent = $user_agents[rand @user_agents];
        my $response_time = sprintf("%.3f", rand(5) + 0.001);
        
        my $log_line = sprintf(
            '%s - - [%s] "%s %s HTTP/1.1" %d %d "-" "%s" %s',
            $ip,
            $timestamp->strftime('%Y-%m-%d %H:%M:%S'),
            $method,
            $path,
            $status,
            $size,
            $user_agent,
            $response_time
        );
        
        print $fh "$log_line\n";
    }
    
    close $fh;
    print "Nginx logs written to $output_file\n";
}

sub generate_error_logs {
    my ($count, $output_file) = @_;
    
    open my $fh, '>', $output_file or die "Cannot open $output_file: $!";
    
    my @error_messages = (
        'File not found',
        'Permission denied',
        'Database connection failed',
        'Memory allocation error',
        'Timeout occurred',
        'Invalid request format',
    );
    
    my @error_levels = qw(ERROR WARN INFO DEBUG);
    
    print "Generating $count error log entries...\n";
    
    for my $i (1..$count) {
        my $timestamp = DateTime->now->subtract(minutes => rand(1440));
        my $level = $error_levels[rand @error_levels];
        my $message = $error_messages[rand @error_messages];
        my $ip = $ips[rand @ips];
        my $path = $paths[rand @paths];
        
        my $log_line = sprintf(
            '[%s] [%s] %s, client: %s, request: "GET %s HTTP/1.1"',
            $timestamp->strftime('%Y-%m-%d %H:%M:%S'),
            lc($level),
            $message,
            $ip,
            $path
        );
        
        print $fh "$log_line\n";
    }
    
    close $fh;
    print "Error logs written to $output_file\n";
}

sub parse_and_store_logs {
    my @log_files = @_;
    
    # Connect to database
    my $dsn = sprintf("dbi:Pg:dbname=%s;host=%s;port=%s",
        $ENV{DB_NAME} || 'log_dashboard',
        $ENV{DB_HOST} || 'localhost',
        $ENV{DB_PORT} || '5432'
    );
    
    my $dbh = DBI->connect($dsn,
        $ENV{DB_USER} || 'postgres',
        $ENV{DB_PASSWORD} || 'postgres',
        { RaiseError => 1, AutoCommit => 1 }
    ) or die "Cannot connect to database: $DBI::errstr";
    
    my $parser = LogDashboard::Parser->new();
    
    # Prepare insert statement
    my $sth = $dbh->prepare(q{
        INSERT INTO log_entries (
            log_type, ip_address, timestamp, method, path, 
            status_code, response_size, user_agent, response_time,
            level, message
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    });
    
    my $total_parsed = 0;
    
    for my $file_info (@log_files) {
        my ($file_path, $format) = @$file_info;
        
        print "Parsing $file_path ($format format)...\n";
        
        open my $fh, '<', $file_path or die "Cannot open $file_path: $!";
        
        my $count = 0;
        while (my $line = <$fh>) {
            chomp $line;
            
            my $parsed = $parser->parse_log_line($line, $format);
            next unless $parsed;
            
            $sth->execute(
                $parsed->{log_type},
                $parsed->{ip_address},
                $parsed->{timestamp},
                $parsed->{method},
                $parsed->{path},
                $parsed->{status_code},
                $parsed->{response_size},
                $parsed->{user_agent},
                $parsed->{response_time},
                $parsed->{level},
                $parsed->{message}
            );
            
            $count++;
        }
        
        close $fh;
        print "Parsed and stored $count entries from $file_path\n";
        $total_parsed += $count;
    }
    
    $dbh->disconnect;
    print "\nTotal entries parsed and stored: $total_parsed\n";
}

# Main execution
sub main {
    # Create logs directory
    mkdir 'logs' unless -d 'logs';
    
    # Generate sample log files
    generate_apache_logs(500, 'logs/apache_access.log');
    generate_nginx_logs(300, 'logs/nginx_access.log');
    generate_error_logs(100, 'logs/error.log');
    
    print "\nParsing and storing logs in database...\n";
    
    # Parse and store in database
    parse_and_store_logs(
        ['logs/apache_access.log', 'apache'],
        ['logs/nginx_access.log', 'nginx'],
        ['logs/error.log', 'error']
    );
    
    print "\nSample log generation and parsing complete!\n";
    print "You can now view the dashboard at http://localhost:5000\n";
}

main() if __FILE__ eq $0; 