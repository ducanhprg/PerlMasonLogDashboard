# Perl Mason PostgreSQL Log Dashboard - Demo

## 🚀 Quick Start (5 Minutes)

### 1. Start the Demo
```bash
git clone <repository-url>
cd PerlMasonLogDashboard

# Start everything
docker compose up --build -d
```

### 2. Generate Sample Data
```bash
# Create realistic log data (500 Apache + 300 Nginx + 100 Error logs)
docker exec log_dashboard_app perl bin/generate_sample_logs.pl
```

### 3. View the Dashboard
```bash
# Open in browser
open http://localhost:5000
```

## 📊 What You'll See

### Dashboard Features
- **Request Stats** - Total requests, error rates, response times, health scores
- **Interactive Charts** - Status code distribution, error trends over 24h
- **Advanced Pagination** - Navigate logs with different page sizes (5, 10, 25, 50, 100)
- **Smart Filtering** - Filter by log type, IP address, status code, HTTP method
- **Direct Navigation** - Jump to any page or use First/Last buttons
- **Top IPs** - See which addresses generate most traffic
- **System Health** - Health score and system status monitoring

### API Endpoints
```bash
# Dashboard statistics with business logic
curl http://localhost:5000/api/stats

# Paginated logs with filtering and validation
curl "http://localhost:5000/api/recent-logs?page=1&limit=10&log_type=access"

# Error trend analysis with business rules
curl "http://localhost:5000/api/error-trends?hours=24"

# Application health check
curl http://localhost:5000/api/health
```

## 🏗️ Architecture Showcase

### Architecture Layers
```
HTTP Request → Controller → Use Case → Repository → Database
Database → Entity → Use Case → DTO → Controller → JSON Response
```

### **Domain Layer** (Business Rules)
```perl
# Domain Entity with business validation
package LogDashboard::Domain::Entity::LogEntry;

sub new {
    my ($class, %args) = @_;
    # Validate business invariants
    die "Invalid log_type" unless $args{log_type} =~ /^(access|error)$/;
    # ...
}

sub is_error {
    my $self = shift;
    return $self->log_type eq 'error' || 
           ($self->status_code && $self->status_code >= 400);
}

sub get_severity_level {
    my $self = shift;
    return 'CRITICAL' if $self->is_server_error;
    return 'WARNING' if $self->is_client_error;
    return 'INFO';
}
```

### **Application Layer** (Use Cases)
```perl
# Use Case with business logic orchestration
package LogDashboard::Application::UseCase::GetDashboardStats;

sub execute {
    my $self = shift;
    
    # Orchestrate multiple repository calls
    my $stats = {};
    $stats->{total_requests} = $self->{log_repository}->count_all();
    $stats->{error_count} = $self->{log_repository}->count_errors();
    
    # Apply business rules
    $stats->{error_rate} = $self->_calculate_error_rate(...);
    $stats->{health_score} = $self->_calculate_health_score(...);
    $stats->{status} = $self->_determine_system_status(...);
    
    return $stats;
}
```

### **Infrastructure Layer** (Data Access)
```perl
# Repository implementation with SQL abstraction
package LogDashboard::Infrastructure::Repository::PostgreSQLLogEntryRepository;

sub find_paginated {
    my ($self, $page, $limit, %filters) = @_;
    
    # Build dynamic WHERE clause
    my @where_conditions;
    my @bind_params;
    
    if ($filters{log_type}) {
        push @where_conditions, "log_type = ?";
        push @bind_params, $filters{log_type};
    }
    
    # Execute with prepared statements (security)
    my $sql = qq{
        SELECT id, log_type, ip_address, timestamp, method, path, 
               status_code, response_size, user_agent, response_time,
               level, message, created_at
        FROM log_entries 
        WHERE $where_clause
        ORDER BY timestamp DESC 
        LIMIT ? OFFSET ?
    };
    
    # Return domain entities
    return [map { $self->_build_entity($_) } @$rows];
}
```

### **Presentation Layer** (HTTP Handling)
```perl
# Thin controller that delegates to use cases
package LogDashboard::Presentation::Controller::DashboardController;

sub handle_stats_request {
    my ($self, $req) = @_;
    
    eval {
        # Delegate to use case
        my $stats = $self->{get_dashboard_stats_use_case}->execute();
        
        # Return JSON response
        return $self->_json_response(200, $stats);
    };
    
    if ($@) {
        return $self->_error_response(500, "Failed to get dashboard stats: $@");
    }
}
```

### **Dependency Injection** (App Bootstrap)
```perl
# Clean dependency injection in bin/app.pl
sub create_application {
    # Infrastructure Layer
    my $db_connection = DatabaseConnection->new();
    my $log_repository = PostgreSQLLogEntryRepository->new($dbh);
    
    # Application Layer  
    my $get_stats_use_case = GetDashboardStats->new($log_repository);
    
    # Presentation Layer
    my $controller = DashboardController->new(
        get_dashboard_stats_use_case => $get_stats_use_case
    );
    
    return { dashboard_controller => $controller };
}
```

## 💡 Technology Showcase

### **Perl Text Processing** (Domain Service)
```perl
# Complex regex with named capture groups
my $regex = qr/
    ^(?<ip>\S+)                    # IP address
    \s+\S+\s+\S+                  # remote logname and user
    \s+\[(?<timestamp>[^\]]+)\]   # timestamp
    \s+"(?<method>\S+)\s+(?<path>\S+)\s+\S+" # method, path, protocol
    \s+(?<status>\d+)             # status code
    \s+(?<size>\d+|-)             # response size
/x;

# Automatic format detection
sub parse_log_line {
    my ($self, $line, $format_hint) = @_;
    
    # Auto-detect format based on line structure
    if ($line =~ /^\[.*?\]\s+\[.*?\]/) {
        return $self->parse_error_log($line);
    } elsif ($line =~ /^{.*}$/) {
        return $self->parse_nginx_log($line);
    } elsif ($line =~ /^\S+.*\[.*?\].*".*".*\d+/) {
        return $self->parse_apache_log($line);
    }
}
```

### **Mason Components** (Presentation)
```mason
<%args>
$title
$value
$icon => ''
$id => ''
</%args>

<div class="card stats-card" <% $id ? qq{id="$id"} : '' %>>
    <div class="card-body">
        <div class="stats-icon text-primary">
% if ($icon eq 'requests') {
            <i class="bi bi-bar-chart-fill" style="font-size: 3rem;"></i>
% } elsif ($icon eq 'error') {
            <i class="bi bi-exclamation-triangle-fill text-warning" style="font-size: 3rem;"></i>
% }
        </div>
        <h5 class="card-title text-muted"><% $title %></h5>
        <p class="card-text display-6"><% $value %></p>
    </div>
</div>
```

### **PostgreSQL Analytics** (Infrastructure)
```sql
-- Time-series error analysis with business logic
SELECT DATE_TRUNC('hour', timestamp) as hour,
       COUNT(*) as total_requests,
       COUNT(CASE WHEN status_code >= 400 THEN 1 END) as errors,
       ROUND(
           (COUNT(CASE WHEN status_code >= 400 THEN 1 END)::float / 
            COUNT(*)::float) * 100, 2
       ) as error_rate
FROM log_entries 
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour;

-- Top IPs with request distribution
SELECT ip_address, 
       COUNT(*) as total_requests,
       COUNT(CASE WHEN status_code >= 400 THEN 1 END) as errors,
       AVG(response_time) as avg_response_time
FROM log_entries 
GROUP BY ip_address 
ORDER BY total_requests DESC 
LIMIT 5;
```

## 🧪 Testing the Architecture

```bash
# Run integration tests
docker exec log_dashboard_app prove test/integration/

# Test specific API endpoints
curl -s http://localhost:5000/api/health | jq .
curl -s "http://localhost:5000/api/stats" | jq .
curl -s "http://localhost:5000/api/recent-logs?limit=5" | jq .pagination
```

## 🔧 Development Commands

```bash
# View application logs
docker compose logs -f app

# Access database directly
docker exec -it log_dashboard_db psql -U postgres -d log_dashboard

# Restart application (after code changes)
docker container restart log_dashboard_app

# Generate more test data
docker exec log_dashboard_app perl bin/generate_sample_logs.pl

# Check container status
docker compose ps
```

## 🏭 Production Deployment

```bash
# Deploy with production configuration
docker compose -f docker-compose.prod.yml up --build -d

# Check production health
curl http://localhost/api/health
```

## 📚 Key Learning Points

### **Architecture Benefits**
1. **Testable** - Business logic isolated from HTTP/Database
2. **Maintainable** - Clear separation of concerns
3. **Flexible** - Easy to swap implementations
4. **Scalable** - Patterns support growth

### **Professional Patterns**
1. **Repository Pattern** - Data access abstraction
2. **Use Case Pattern** - Business logic encapsulation
3. **Dependency Injection** - Loose coupling
4. **Entity Pattern** - Business rules with data

### **Code Quality**
1. **SOLID Principles** - Single responsibility, dependency inversion
2. **Clean Code** - Readable, maintainable, well-structured
3. **Domain-Driven Design** - Business logic in domain layer
4. **Error Handling** - Proper exception handling and logging

This demonstrates the **massive difference** between script-kiddie code and professional software engineering. The same functionality, but with proper architecture, testability, and maintainability. 