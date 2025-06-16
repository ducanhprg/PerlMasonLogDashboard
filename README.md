# Perl Mason PostgreSQL Log Dashboard - Demo Project

## 🎯 Project Purpose

This is a **demonstration project** showcasing the power and capabilities of:

- **Perl** - Advanced text processing and regex capabilities
- **Mason** - Component-based templating system  
- **PostgreSQL** - Complex queries and analytics

**This is NOT a production application** - it's designed to demonstrate how these mature technologies work together to create powerful web applications for log analysis and data processing.

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
- **Real-time Statistics** - Total requests, error rates, response times
- **Interactive Charts** - Status code distribution and error trends
- **Advanced Pagination** - Navigate through log entries with multiple page sizes
- **Top IP Analysis** - See which IPs generate the most traffic

### Technology Demonstrations

#### Perl Text Processing
- Complex regex patterns for parsing Apache, Nginx, and error logs
- Automatic log format detection
- Efficient handling of large datasets
- Clean object-oriented design

#### Mason Templating
- Component-based template architecture
- Embedded Perl logic in templates
- Template inheritance and reuse
- Clean separation of presentation and business logic

#### PostgreSQL Analytics
- Complex aggregation queries
- Time-series analysis with DATE_TRUNC
- Efficient indexing for fast queries
- Advanced SQL features for log analysis

## 📊 Sample Data

The demo includes a data generator that creates:
- **500 Apache access logs** with realistic IPs, paths, and status codes
- **300 Nginx access logs** demonstrating different log formats
- **100 Error logs** with structured error messages
- **Time-distributed data** spread across the last 24 hours

## 🔧 Demo Commands

```bash
# View application logs
docker compose logs -f app

# Generate more sample data
docker exec log_dashboard_app perl bin/generate_sample_logs.pl

# Access database directly
docker exec -it log_dashboard_db psql -U postgres -d log_dashboard

# Run tests
docker exec log_dashboard_app prove test/integration/

# Stop the demo
docker compose down
```

## 🏭 Production Considerations

For production use, see `docker-compose.prod.yml` which includes:
- Nginx reverse proxy with load balancing
- Multiple application instances
- Redis caching layer
- Proper security configurations
- Resource limits and health checks

## 🎯 Learning Objectives

This demo illustrates:

1. **Perl's Strengths** - Unmatched text processing capabilities
2. **Mason's Power** - Flexible, component-based web templating
3. **PostgreSQL's Features** - Advanced SQL and analytics capabilities
4. **Integration Patterns** - How these technologies work together
5. **Modern Deployment** - Containerized applications with Docker

## 📚 Use Cases

This technology stack is excellent for:
- Log analysis and monitoring systems
- Content management systems
- Data processing applications
- Reporting and analytics platforms
- Any application requiring sophisticated text processing

## 🤝 Contributing

This is a demonstration project. Feel free to:
- Explore the code to understand the patterns
- Modify the log parsing to handle your formats
- Add new visualizations or features
- Use it as a starting point for your own projects

## 📄 License

This demo project is provided as-is for educational and demonstration purposes. 