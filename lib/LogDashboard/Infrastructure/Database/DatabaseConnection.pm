package LogDashboard::Infrastructure::Database::DatabaseConnection;

use strict;
use warnings;
use DBI;

# Database Connection Service
# Follows SOLID principles: single responsibility, dependency inversion

sub new {
    my ($class, %config) = @_;
    
    # Set defaults from environment or config
    my $self = {
        host => $config{host} || $ENV{DB_HOST} || 'localhost',
        port => $config{port} || $ENV{DB_PORT} || '5432',
        database => $config{database} || $ENV{DB_NAME} || 'log_dashboard',
        username => $config{username} || $ENV{DB_USER} || 'postgres',
        password => $config{password} || $ENV{DB_PASSWORD} || 'postgres',
        options => $config{options} || {
            RaiseError => 1,
            AutoCommit => 1,
            pg_enable_utf8 => 1,
        },
        _dbh => undef,
    };
    
    return bless $self, $class;
}

sub get_connection {
    my $self = shift;
    
    # Return existing connection if still active
    if ($self->{_dbh} && $self->_is_connection_alive()) {
        return $self->{_dbh};
    }
    
    # Create new connection
    $self->{_dbh} = $self->_create_connection();
    return $self->{_dbh};
}

sub disconnect {
    my $self = shift;
    
    if ($self->{_dbh}) {
        $self->{_dbh}->disconnect();
        $self->{_dbh} = undef;
    }
}

sub is_connected {
    my $self = shift;
    return $self->{_dbh} && $self->_is_connection_alive();
}

sub execute_in_transaction {
    my ($self, $code_ref) = @_;
    
    die "Code reference required" unless ref($code_ref) eq 'CODE';
    
    my $dbh = $self->get_connection();
    
    # Begin transaction
    $dbh->begin_work();
    
    my $result;
    eval {
        $result = $code_ref->($dbh);
        $dbh->commit();
    };
    
    if ($@) {
        $dbh->rollback();
        die "Transaction failed: $@";
    }
    
    return $result;
}

sub health_check {
    my $self = shift;
    
    eval {
        my $dbh = $self->get_connection();
        $dbh->do("SELECT 1");
    };
    
    return $@ ? 0 : 1;
}

# Private methods
sub _create_connection {
    my $self = shift;
    
    my $dsn = sprintf("dbi:Pg:dbname=%s;host=%s;port=%s",
        $self->{database},
        $self->{host},
        $self->{port}
    );
    
    # Retry connection with backoff for container startup
    my $max_retries = 5;
    my $retry_delay = 2; # seconds
    
    for my $attempt (1..$max_retries) {
        my $dbh = eval {
            DBI->connect(
                $dsn,
                $self->{username},
                $self->{password},
                $self->{options}
            );
        };
        
        if ($dbh) {
            return $dbh;
        }
        
        if ($attempt < $max_retries) {
            warn "Database connection attempt $attempt failed, retrying in ${retry_delay}s: $DBI::errstr";
            sleep $retry_delay;
            $retry_delay *= 2; # Exponential backoff
        }
    }
    
    die "Cannot connect to database after $max_retries attempts: " . ($DBI::errstr || 'Unknown error');
}

sub _is_connection_alive {
    my $self = shift;
    
    return 0 unless $self->{_dbh};
    
    eval {
        $self->{_dbh}->ping();
    };
    
    return $@ ? 0 : 1;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect();
}

1; 