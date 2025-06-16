# Perl Mason PostgreSQL Log Dashboard - Quick Demo Guide

## 🎯 What This Demo Shows

This demonstrates how **Perl**, **Mason**, and **PostgreSQL** work together for log analysis:

- **Perl**: Powerful regex parsing of log files
- **Mason**: Component-based web templating  
- **PostgreSQL**: Complex analytics queries

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
- **Real-time Stats**: Total requests, error rates, response times
- **Interactive Charts**: Status code distribution, error trends over 24h
- **Advanced Pagination**: Navigate logs with different page sizes (5, 10, 25, 50, 100)
- **Direct Navigation**: Jump to any page or use First/Last buttons
- **Top IPs**: See which addresses generate most traffic

### Technology Showcase

**Perl Text Processing:**
```perl
# Apache log parsing with complex regex
my $regex = qr/
    ^(\S+)                    # IP address
    \s+\S+\s+\S+             # remote logname and user
    \s+\[([^\]]+)\]          # timestamp
    \s+"(\S+)\s+(\S+)\s+\S+" # method, path, protocol
    \s+(\d+)                 # status code
    \s+(\d+|-)               # response size
/x;
```

**Mason Components:**
```mason
<%args>
$title
$value
$icon
</%args>
<div class="card stats-card">
    <div class="card-body">
        <h5><% $title %></h5>
        <p class="display-6"><% $value %></p>
    </div>
</div>
```

**PostgreSQL Analytics:**
```sql
-- Time-series error analysis
SELECT DATE_TRUNC('hour', timestamp) as hour,
       COUNT(*) as total_requests,
       COUNT(CASE WHEN status_code >= 400 THEN 1 END) as errors
FROM log_entries 
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY hour ORDER BY hour;
```

## 🔧 Demo Commands

```bash
# View logs
docker compose logs -f app

# Generate more data
docker exec log_dashboard_app perl bin/generate_sample_logs.pl

# Access database
docker exec -it log_dashboard_db psql -U postgres -d log_dashboard

# Run tests
docker exec log_dashboard_app prove test/integration/

# Stop demo
docker compose down
```

## 🧪 Test the Features

1. **Pagination**: Change "Show: 10 entries" to 25 or 50
2. **Navigation**: Use "Go to:" field to jump to page 20
3. **Charts**: Watch real-time updates every 30 seconds
4. **Data**: Generate more logs and see stats update

## 🏭 Production Setup

For production deployment:
```bash
# Use production configuration
docker compose -f docker-compose.prod.yml up -d
```

Production includes:
- Nginx reverse proxy
- Multiple app instances (3x)
- Redis caching
- Health checks
- Resource limits

## 🎯 Key Takeaways

This demo proves that **Perl + Mason + PostgreSQL** is:

- **Powerful**: Complex log parsing with regex mastery
- **Flexible**: Component-based templates with embedded logic
- **Fast**: Efficient queries and real-time analytics
- **Modern**: Containerized deployment with Docker
- **Scalable**: Production-ready with load balancing

Perfect for log analysis, content management, data processing, and any application requiring sophisticated text processing with web interfaces. 