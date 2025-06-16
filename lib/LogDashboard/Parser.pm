package LogDashboard::Parser;

use strict;
use warnings;
use DateTime::Format::Strptime;

# Showcasing Perl's powerful regex and text processing capabilities

sub new {
    my $class = shift;
    my $self = {
        # Date parsers for different log formats
        apache_parser => DateTime::Format::Strptime->new(
            pattern => '%d/%b/%Y:%H:%M:%S %z'
        ),
        nginx_parser => DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d %H:%M:%S'
        ),
    };
    return bless $self, $class;
}

# Parse Apache Common Log Format and Combined Log Format
# Demonstrates Perl's regex prowess for complex text parsing
sub parse_apache_log {
    my ($self, $line) = @_;
    
    # Apache Combined Log Format regex - showcasing Perl's regex power
    my $regex = qr/
        ^(\S+)                    # IP address
        \s+\S+\s+\S+             # remote logname and remote user (ignored)
        \s+\[([^\]]+)\]          # timestamp
        \s+"(\S+)\s+(\S+)\s+\S+" # method, path, protocol
        \s+(\d+)                 # status code
        \s+(\d+|-)               # response size
        (?:\s+"([^"]*)")?        # referer (optional)
        (?:\s+"([^"]*)")?        # user agent (optional)
        (?:\s+(\d+))?            # response time in microseconds (optional)
    /x;
    
    if ($line =~ /$regex/) {
        my ($ip, $timestamp_str, $method, $path, $status, $size, $referer, $user_agent, $response_time) = 
           ($1, $2, $3, $4, $5, $6, $7, $8, $9);
        
        # Parse timestamp using DateTime
        my $timestamp = $self->{apache_parser}->parse_datetime($timestamp_str);
        
        return {
            log_type => 'access',
            ip_address => $ip,
            timestamp => $timestamp ? $timestamp->iso8601() : undef,
            method => $method,
            path => $path,
            status_code => int($status),
            response_size => ($size eq '-') ? undef : int($size),
            referer => $referer,
            user_agent => $user_agent,
            response_time => $response_time ? int($response_time) / 1000 : undef, # Convert to ms
        };
    }
    
    return undef;
}

# Parse Nginx JSON format logs
# Demonstrates Perl's JSON handling and flexible parsing
sub parse_nginx_log {
    my ($self, $line) = @_;
    
    # Try to parse as JSON first (modern Nginx format)
    eval {
        require JSON::XS;
        my $json = JSON::XS->new->decode($line);
        
        if ($json->{timestamp} && $json->{request}) {
            # Extract method and path from request string
            my ($method, $path) = $json->{request} =~ /^(\S+)\s+(\S+)/;
            
            return {
                log_type => 'access',
                ip_address => $json->{remote_addr},
                timestamp => $json->{timestamp},
                method => $method,
                path => $path,
                status_code => int($json->{status} || 0),
                response_size => int($json->{body_bytes_sent} || 0),
                referer => $json->{http_referer},
                user_agent => $json->{http_user_agent},
                response_time => $json->{request_time} ? $json->{request_time} * 1000 : undef,
            };
        }
    };
    
    # Fallback to standard Nginx log format parsing
    my $regex = qr/
        ^(\S+)                    # IP address
        \s+-\s+-                  # remote user info
        \s+\[([^\]]+)\]          # timestamp
        \s+"([^"]+)"             # request line
        \s+(\d+)                 # status
        \s+(\d+)                 # bytes sent
        \s+"([^"]*)"             # referer
        \s+"([^"]*)"             # user agent
        (?:\s+"[^"]*")?          # additional fields
        (?:\s+(\d+\.\d+))?       # request time
    /x;
    
    if ($line =~ /$regex/) {
        my ($ip, $timestamp_str, $request, $status, $size, $referer, $user_agent, $request_time) = 
           ($1, $2, $3, $4, $5, $6, $7, $8);
        
        # Parse request line
        my ($method, $path) = $request =~ /^(\S+)\s+(\S+)/;
        
        # Parse timestamp
        my $timestamp = $self->{nginx_parser}->parse_datetime($timestamp_str);
        
        return {
            log_type => 'access',
            ip_address => $ip,
            timestamp => $timestamp ? $timestamp->iso8601() : undef,
            method => $method,
            path => $path,
            status_code => int($status),
            response_size => int($size),
            referer => $referer,
            user_agent => $user_agent,
            response_time => $request_time ? $request_time * 1000 : undef,
        };
    }
    
    return undef;
}

# Parse application error logs
# Demonstrates structured error log parsing
sub parse_error_log {
    my ($self, $line) = @_;
    
    # Error log format: [timestamp] [level] message
    my $regex = qr/
        ^\[([^\]]+)\]            # timestamp
        \s+\[([^\]]+)\]          # log level
        \s+(.+)                  # message
    /x;
    
    if ($line =~ /$regex/) {
        my ($timestamp_str, $level, $message) = ($1, $2, $3);
        
        # Try to extract IP and path from error message
        my ($ip) = $message =~ /client:\s*([^,\s]+)/;
        my ($path) = $message =~ /request:\s*"\w+\s+(\S+)\s+HTTP/;
        
        return {
            log_type => 'error',
            timestamp => $timestamp_str,
            level => uc($level),
            message => $message,
            ip_address => $ip,
            path => $path,
        };
    }
    
    return undef;
}

# Main parsing method - demonstrates Perl's flexibility
sub parse_log_line {
    my ($self, $line, $format_hint) = @_;
    
    # Skip empty lines and comments
    return undef if !$line || $line =~ /^\s*$/ || $line =~ /^\s*#/;
    
    # Try different parsers based on format hint or line characteristics
    if ($format_hint) {
        if ($format_hint eq 'apache') {
            return $self->parse_apache_log($line);
        } elsif ($format_hint eq 'nginx') {
            return $self->parse_nginx_log($line);
        } elsif ($format_hint eq 'error') {
            return $self->parse_error_log($line);
        }
    }
    
    # Auto-detect format based on line structure
    if ($line =~ /^\[.*?\]\s+\[.*?\]/) {
        # Looks like error log format
        return $self->parse_error_log($line);
    } elsif ($line =~ /^{.*}$/) {
        # Looks like JSON format (Nginx)
        return $self->parse_nginx_log($line);
    } elsif ($line =~ /^\S+.*\[.*?\].*".*".*\d+/) {
        # Looks like Apache format
        return $self->parse_apache_log($line);
    } else {
        # Try Nginx standard format
        return $self->parse_nginx_log($line);
    }
}

1; 