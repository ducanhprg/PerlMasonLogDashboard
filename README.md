# Perl Mason PostgreSQL Log Dashboard - Demo

## 🎯 Project Purpose

This is a **Perl demonstration project** showcasing:
- **Perl** - Advanced text processing and regex capabilities
- **Mason** - Component-based templating system  
- **PostgreSQL** - Complex queries and analytics

## 🏗️ Architecture Highlights

### Architecture Layers
```
┌─────────────────────────────────────────┐
│    Presentation (Controllers/HTTP)      │
│  ┌─────────────────────────────────────┐│
│  │    Application (Use Cases)          ││
│  │  ┌─────────────────────────────────┐││
│  │  │    Domain (Entities/Rules)      │││
│  │  └─────────────────────────────────┘││
│  └─────────────────────────────────────┘│
│    Infrastructure (Database/External)   │
└─────────────────────────────────────────┘
```

### Key Patterns Implemented
- **Repository Pattern** - Data access abstraction
- **Use Case Pattern** - Business logic encapsulation
- **Dependency Injection** - Loose coupling, testable code
- **Entity Pattern** - Business rules with data validation

## 🚀 Quick Demo Setup

### Prerequisites
- Docker & Docker Compose
- Git

### Start the Demo
```bash
# Clone the repository
git clone <repository-url>
cd PerlMasonLogDashboard

# Start the demo environment
docker compose up --build -d

# Generate sample log data
docker exec log_dashboard_app perl bin/generate_sample_logs.pl

# Access the dashboard
open http://localhost:5000
```

That's it! The demo is now running with sample data.

## 🎪 What You'll See

### Live Dashboard Features
- **Real-time Statistics** - Total requests, error rates, response times, health scores
- **Interactive Charts** - Status code distribution and error trends over time
- **Advanced Pagination** - Navigate through log entries (5-100 per page)
- **Smart Filtering** - Filter by log type, IP address, status code, HTTP method
- **Top IP Analysis** - See which IPs generate the most traffic
- **System Health Monitoring** - Health score and system status indicators

### API Endpoints
- `GET /api/stats` - Dashboard statistics with business logic
- `GET /api/recent-logs?page=1&limit=10` - Paginated logs with filtering
- `GET /api/error-trends?hours=24` - Error trend analysis
- `GET /api/health` - Application health check

### Technology Demonstrations

#### Implementation
```perl
# Domain Entity with business rules
package LogDashboard::Domain::Entity::LogEntry;
sub is_error { return $_[0]->status_code >= 400; }
sub get_severity_level { ... }

# Use Case with business logic
package LogDashboard::Application::UseCase::GetDashboardStats;
sub execute { 
    # Orchestrate repository calls
    # Apply business rules
    # Return computed metrics
}

# Repository abstraction
package LogDashboard::Domain::Repository::LogEntryRepositoryInterface;
sub find_paginated { die "Must be implemented"; }

# Clean controller
package LogDashboard::Presentation::Controller::DashboardController;
sub handle_stats_request {
    # Delegate to use case
    # Return JSON response
}
```

#### Perl Text Processing
- Complex regex patterns for parsing Apache, Nginx, and error logs
- Automatic log format detection and validation
- Efficient handling of large datasets with streaming
- Clean object-oriented design with proper encapsulation

#### Mason Templating
- Component-based template architecture with reusable components
- Embedded Perl logic in templates with clean separation
- Template inheritance and composition patterns
- UTF-8 support with proper encoding handling

#### PostgreSQL Analytics
- Complex aggregation queries with time-series analysis
- Efficient indexing strategies for fast log queries
- Advanced SQL features (DATE_TRUNC, window functions)
- Prepared statements with parameter binding for security

## 📊 Sample Data

The demo includes a data generator that creates:
- **500 Apache access logs** with realistic IPs, paths, and status codes
- **300 Nginx access logs** demonstrating different log formats
- **100 Error logs** with structured error messages and severity levels
- **Time-distributed data** spread across the last 24 hours for trend analysis

## 🔧 Demo Commands

```bash
# View application logs
docker compose logs -f app

# Generate more sample data
docker exec log_dashboard_app perl bin/generate_sample_logs.pl

# Access database directly
docker exec -it log_dashboard_db psql -U postgres -d log_dashboard

# Run integration tests
docker exec log_dashboard_app prove test/integration/

# Restart application (after code changes)
docker container restart log_dashboard_app

# Stop the demo
docker compose down
```

## 🏭 Production Deployment

For production use, see `docker-compose.prod.yml` which includes:
- **Nginx reverse proxy** with load balancing across multiple app instances
- **Multiple application instances** (3 replicas) with health checks
- **Redis caching layer** for improved performance
- **Proper security configurations** with non-root users and network isolation
- **Resource limits and monitoring** with comprehensive health checks
- **Production PSGI server** (Starman) with optimized performance

```bash
# Deploy to production
docker compose -f docker-compose.prod.yml up --build -d
```

## 🎯 Learning Objectives

This demo illustrates professional software development:

### **Technology Integration**
1. **Perl's Strengths** - Text processing capabilities
2. **Mason's Power** - Flexible, component-based web templating
3. **PostgreSQL's Features** - Advanced SQL and analytics capabilities
4. **Modern Deployment** - Containerized applications with Docker

### **Code Quality**
1. **Maintainability** - Clear separation of concerns
2. **Testability** - Business logic isolated from infrastructure
3. **Flexibility** - Easy to extend and modify
4. **Scalability** - Patterns that support growth

## 📚 Use Cases

This architecture is excellent for:
- **Log Analysis Systems** - High-volume data processing and analytics
- **Content Management Systems** - Flexible templating and data modeling
- **Reporting Platforms** - Complex queries and data visualization
- **Microservices** - Clear boundaries and testable components

## 🧪 Testing Strategy

### Current Tests
```bash
# Run integration tests
docker exec log_dashboard_app prove test/integration/
```

### Testing Layers
- **Domain Entities** - Business rule validation
- **Use Cases** - Business logic with mocked repositories
- **Repositories** - Data access with test database
- **Controllers** - HTTP endpoints with real dependencies

## 📂 Project Structure

```
lib/LogDashboard/
├── Domain/                          # Business Logic (Inner Layer)
│   ├── Entity/
│   │   └── LogEntry.pm             # Domain entity with business rules
│   └── Repository/
│       └── LogEntryRepositoryInterface.pm  # Repository contract
│
├── Application/                     # Use Cases (Application Layer)
│   └── UseCase/
│       ├── GetDashboardStats.pm    # Business logic orchestration
│       ├── GetRecentLogs.pm        # Pagination and filtering logic
│       └── GetErrorTrends.pm       # Trend analysis with business rules
│
├── Infrastructure/                  # External Concerns (Outer Layer)
│   ├── Database/
│   │   └── DatabaseConnection.pm   # Database connection management
│   └── Repository/
│       └── PostgreSQLLogEntryRepository.pm  # Concrete repository
│
├── Presentation/                    # HTTP/Web Layer (Outer Layer)
│   └── Controller/
│       └── DashboardController.pm  # HTTP request handling
│
└── Parser.pm                       # Domain service (text processing)
```

## 🤝 Contributing

This is a demonstration project. Feel free to:
- **Modify the business logic** to see how changes propagate through layers
- **Add new features** following the established patterns
- **Use as a template** for your own professional projects

## 📄 Documentation

- **[DEMO_GUIDE.md](DEMO_GUIDE.md)** - Quick start guide for evaluation
- **API Documentation** - Available at `/api/health` endpoint

## 📈 Performance & Monitoring

- **Health Check Endpoint** - `/api/health` for monitoring
- **Structured Logging** - JSON logs for aggregation
- **Database Indexing** - Optimized for log query patterns
- **Connection Pooling** - Efficient database resource usage
- **Caching Strategy** - Redis for production environments