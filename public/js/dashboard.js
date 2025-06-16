// Dashboard JavaScript
class LogDashboard {
    constructor() {
        this.charts = {};
        this.refreshInterval = 30000; // 30 seconds
        this.init();
    }

    init() {
        this.loadCharts();
        this.loadRecentLogs();
        this.startAutoRefresh();
    }

    async loadCharts() {
        try {
            await Promise.all([
                this.loadErrorChart(),
                this.loadStatusChart(),
                this.loadResponseTimeChart()
            ]);
        } catch (error) {
            console.error('Error loading charts:', error);
        }
    }

    async loadErrorChart() {
        const response = await fetch('/api/errors/summary?hours=24');
        const data = await response.json();
        
        const ctx = document.getElementById('errorChart').getContext('2d');
        
        // Process data for chart
        const hours = [...new Set(data.map(item => item.hour))].sort();
        const levels = ['ERROR', 'CRITICAL', 'WARNING'];
        
        const datasets = levels.map(level => {
            const color = this.getLevelColor(level);
            return {
                label: level,
                data: hours.map(hour => {
                    const item = data.find(d => d.hour === hour && d.level === level);
                    return item ? item.count : 0;
                }),
                backgroundColor: color.bg,
                borderColor: color.border,
                borderWidth: 2,
                fill: false
            };
        });

        this.charts.errorChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: hours.map(hour => new Date(hour).toLocaleTimeString()),
                datasets: datasets
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Count'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Time'
                        }
                    }
                },
                plugins: {
                    legend: {
                        position: 'top'
                    },
                    title: {
                        display: true,
                        text: 'Error Trends (Last 24 Hours)'
                    }
                }
            }
        });
    }

    async loadStatusChart() {
        const response = await fetch('/api/http/status-codes?hours=24');
        const data = await response.json();
        
        const ctx = document.getElementById('statusChart').getContext('2d');
        
        this.charts.statusChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: data.map(item => `${item.status_code} (${item.percentage}%)`),
                datasets: [{
                    data: data.map(item => item.count),
                    backgroundColor: data.map(item => this.getStatusColor(item.status_code)),
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'right'
                    },
                    title: {
                        display: true,
                        text: 'HTTP Status Code Distribution'
                    }
                }
            }
        });
    }

    async loadResponseTimeChart() {
        const response = await fetch('/api/performance/response-times?hours=24');
        const data = await response.json();
        
        const ctx = document.getElementById('responseTimeChart').getContext('2d');
        
        this.charts.responseTimeChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(item => new Date(item.hour).toLocaleTimeString()),
                datasets: [
                    {
                        label: 'Average',
                        data: data.map(item => parseFloat(item.avg_response_time)),
                        borderColor: '#3498db',
                        backgroundColor: 'rgba(52, 152, 219, 0.1)',
                        borderWidth: 2,
                        fill: true
                    },
                    {
                        label: '95th Percentile',
                        data: data.map(item => parseFloat(item.p95_response_time)),
                        borderColor: '#e74c3c',
                        backgroundColor: 'rgba(231, 76, 60, 0.1)',
                        borderWidth: 2,
                        fill: false
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Response Time (ms)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Time'
                        }
                    }
                },
                plugins: {
                    legend: {
                        position: 'top'
                    },
                    title: {
                        display: true,
                        text: 'Response Time Trends'
                    }
                }
            }
        });
    }

    async loadRecentLogs() {
        try {
            const response = await fetch('/api/logs/recent?limit=50');
            const logs = await response.json();
            
            const container = document.getElementById('recentLogs');
            container.innerHTML = '';
            
            if (logs.length === 0) {
                container.innerHTML = '<p class="no-logs">No recent logs found</p>';
                return;
            }
            
            logs.forEach(log => {
                const logElement = this.createLogElement(log);
                container.appendChild(logElement);
            });
        } catch (error) {
            console.error('Error loading recent logs:', error);
            document.getElementById('recentLogs').innerHTML = '<p class="error">Error loading logs</p>';
        }
    }

    createLogElement(log) {
        const div = document.createElement('div');
        div.className = 'log-entry';
        
        const timestamp = new Date(log.timestamp).toLocaleString();
        const level = log.level.toLowerCase();
        
        div.innerHTML = `
            <div class="log-level ${level}">${log.level}</div>
            <div class="log-message">${this.escapeHtml(log.message)}</div>
            <div class="log-meta">
                <div class="log-source">${log.source_name}</div>
                <div class="log-timestamp">${timestamp}</div>
            </div>
        `;
        
        return div;
    }

    getLevelColor(level) {
        const colors = {
            'ERROR': { bg: 'rgba(231, 76, 60, 0.2)', border: '#e74c3c' },
            'CRITICAL': { bg: 'rgba(192, 57, 43, 0.2)', border: '#c0392b' },
            'WARNING': { bg: 'rgba(243, 156, 18, 0.2)', border: '#f39c12' },
            'INFO': { bg: 'rgba(52, 152, 219, 0.2)', border: '#3498db' }
        };
        return colors[level] || colors['INFO'];
    }

    getStatusColor(statusCode) {
        if (statusCode >= 500) return '#e74c3c'; // Red for server errors
        if (statusCode >= 400) return '#f39c12'; // Orange for client errors
        if (statusCode >= 300) return '#3498db'; // Blue for redirects
        if (statusCode >= 200) return '#27ae60'; // Green for success
        return '#95a5a6'; // Gray for others
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    startAutoRefresh() {
        setInterval(() => {
            this.refreshData();
        }, this.refreshInterval);
    }

    async refreshData() {
        try {
            // Refresh charts
            await this.loadCharts();
            
            // Refresh recent logs
            await this.loadRecentLogs();
            
            // Update stats in header
            const response = await fetch('/api/dashboard/stats');
            const stats = await response.json();
            
            document.querySelector('.stat-card:nth-child(1) .stat-number').textContent = stats.total_logs_24h;
            document.querySelector('.stat-card:nth-child(2) .stat-number').textContent = stats.errors_24h;
            document.querySelector('.stat-card:nth-child(3) .stat-number').textContent = stats.avg_response_time_1h + 'ms';
            
        } catch (error) {
            console.error('Error refreshing data:', error);
        }
    }

    destroy() {
        // Clean up charts
        Object.values(this.charts).forEach(chart => {
            if (chart) chart.destroy();
        });
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new LogDashboard();
});

// Clean up on page unload
window.addEventListener('beforeunload', () => {
    if (window.dashboard) {
        window.dashboard.destroy();
    }
}); 