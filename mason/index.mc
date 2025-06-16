<%args>
</%args>

<%init>
# This showcases Mason's ability to embed Perl logic directly in templates
my $page_title = "Perl Mason PostgreSQL Log Dashboard";
my $current_time = localtime();
</%init>

<&| components/layout.mc, title => $page_title &>

<div class="container-fluid">
    <div class="row mb-4">
        <div class="col-12">
            <h1 class="display-4">Log Analysis Dashboard</h1>
            <p class="lead">Demonstrating Perl's text processing, Mason's templating, and PostgreSQL's analytics</p>
            <small class="text-muted">Last updated: <% $current_time %></small>
        </div>
    </div>

    <!-- Statistics Cards Row -->
    <div class="row mb-4" id="stats-row">
        <div class="col-md-3">
            <& components/stats_card.mc, 
                title => "Total Requests",
                value => "Loading...",
                icon => "requests",
                id => "total-requests"
            &>
        </div>
        <div class="col-md-3">
            <& components/stats_card.mc, 
                title => "Error Rate",
                value => "Loading...",
                icon => "error",
                id => "error-rate"
            &>
        </div>
        <div class="col-md-3">
            <& components/stats_card.mc, 
                title => "Avg Response Time",
                value => "Loading...",
                icon => "time",
                id => "avg-response-time"
            &>
        </div>
        <div class="col-md-3">
            <& components/stats_card.mc, 
                title => "Active Now",
                value => "Live",
                icon => "status",
                id => "status"
            &>
        </div>
    </div>

    <!-- Charts Row -->
    <div class="row mb-4">
        <div class="col-md-6">
            <& components/chart_container.mc,
                title => "Status Code Distribution",
                chart_id => "status-codes-chart"
            &>
        </div>
        <div class="col-md-6">
            <& components/chart_container.mc,
                title => "Error Trends (24h)",
                chart_id => "error-trends-chart"
            &>
        </div>
    </div>

    <!-- Top IPs and Recent Logs -->
    <div class="row">
        <div class="col-md-4">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0">Top IP Addresses</h5>
                </div>
                <div class="card-body">
                    <div id="top-ips-list">
                        <div class="text-center">
                            <div class="spinner-border spinner-border-sm" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0">Recent Log Entries</h5>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-sm">
                            <thead>
                                <tr>
                                    <th>Time</th>
                                    <th>IP</th>
                                    <th>Method</th>
                                    <th>Path</th>
                                    <th>Status</th>
                                    <th>Response Time</th>
                                </tr>
                            </thead>
                            <tbody id="recent-logs-table">
                                <tr>
                                    <td colspan="6" class="text-center">
                                        <div class="spinner-border spinner-border-sm" role="status">
                                            <span class="visually-hidden">Loading...</span>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <!-- Pagination Controls -->
                    <nav aria-label="Recent logs pagination" id="logs-pagination" style="display: none;">
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <div class="d-flex align-items-center">
                                <small class="text-muted me-3" id="pagination-info"></small>
                                <div class="d-flex align-items-center">
                                    <label for="records-per-page" class="form-label me-2 mb-0">Show:</label>
                                    <select class="form-select form-select-sm me-2" id="records-per-page" style="width: auto;">
                                        <option value="5">5</option>
                                        <option value="10" selected>10</option>
                                        <option value="25">25</option>
                                        <option value="50">50</option>
                                        <option value="100">100</option>
                                    </select>
                                    <small class="text-muted">entries</small>
                                </div>
                            </div>
                            <div class="d-flex align-items-center">
                                <ul class="pagination pagination-sm mb-0 me-3">
                                    <li class="page-item" id="first-page">
                                        <a class="page-link" href="#" id="first-page-btn">First</a>
                                    </li>
                                    <li class="page-item" id="prev-page">
                                        <a class="page-link" href="#" id="prev-page-btn">Previous</a>
                                    </li>
                                    <li class="page-item active" id="current-page">
                                        <span class="page-link" id="current-page-number">1</span>
                                    </li>
                                    <li class="page-item" id="next-page">
                                        <a class="page-link" href="#" id="next-page-btn">Next</a>
                                    </li>
                                    <li class="page-item" id="last-page">
                                        <a class="page-link" href="#" id="last-page-btn">Last</a>
                                    </li>
                                </ul>
                                <div class="d-flex align-items-center">
                                    <label for="goto-page" class="form-label me-2 mb-0">Go to:</label>
                                    <input type="number" class="form-control form-control-sm me-2" id="goto-page" min="1" style="width: 70px;">
                                    <button class="btn btn-sm btn-outline-primary" id="goto-page-btn">Go</button>
                                </div>
                            </div>
                        </div>
                    </nav>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// Dashboard JavaScript - showcasing integration between Mason templates and frontend
class LogDashboard {
    constructor() {
        this.charts = {};
        this.currentPage = 1;
        this.logsPerPage = 10;
        this.init();
    }

    async init() {
        await this.loadStats();
        await this.loadRecentLogs();
        await this.initCharts();
        
        // Setup pagination event listeners
        document.getElementById('prev-page-btn').addEventListener('click', (e) => {
            e.preventDefault();
            if (this.currentPage > 1) {
                this.loadRecentLogs(this.currentPage - 1);
            }
        });
        
        document.getElementById('next-page-btn').addEventListener('click', (e) => {
            e.preventDefault();
            this.loadRecentLogs(this.currentPage + 1);
        });
        
        document.getElementById('first-page-btn').addEventListener('click', (e) => {
            e.preventDefault();
            this.loadRecentLogs(1);
        });
        
        document.getElementById('last-page-btn').addEventListener('click', (e) => {
            e.preventDefault();
            if (this.totalPages) {
                this.loadRecentLogs(this.totalPages);
            }
        });
        
        // Records per page selector
        document.getElementById('records-per-page').addEventListener('change', (e) => {
            this.logsPerPage = parseInt(e.target.value);
            this.loadRecentLogs(1); // Reset to first page when changing page size
        });
        
        // Go to page functionality
        document.getElementById('goto-page-btn').addEventListener('click', (e) => {
            e.preventDefault();
            const pageInput = document.getElementById('goto-page');
            const targetPage = parseInt(pageInput.value);
            if (targetPage && targetPage >= 1 && targetPage <= this.totalPages) {
                this.loadRecentLogs(targetPage);
                pageInput.value = ''; // Clear input after navigation
            } else {
                alert(`Please enter a valid page number between 1 and ${this.totalPages}`);
            }
        });
        
        // Allow Enter key in goto page input
        document.getElementById('goto-page').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                document.getElementById('goto-page-btn').click();
            }
        });
        
        // Auto-refresh every 30 seconds (but keep current page)
        setInterval(() => {
            this.loadStats();
            this.loadRecentLogs(this.currentPage);
        }, 30000);
    }

    async loadStats() {
        try {
            const response = await fetch('/api/stats');
            const data = await response.json();
            
            document.getElementById('total-requests').querySelector('.card-text').textContent = 
                data.total_requests.toLocaleString();
            document.getElementById('error-rate').querySelector('.card-text').textContent = 
                data.error_rate + '%';
            document.getElementById('avg-response-time').querySelector('.card-text').textContent = 
                data.avg_response_time + 'ms';
            
            this.updateTopIPs(data.top_ips);
            this.updateStatusCodesChart(data.status_codes);
            
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    async loadRecentLogs(page = 1) {
        try {
            this.currentPage = page;
            const response = await fetch(`/api/recent-logs?page=${page}&limit=${this.logsPerPage}`);
            const data = await response.json();
            
            const tbody = document.getElementById('recent-logs-table');
            tbody.innerHTML = data.logs.map(log => `
                <tr>
                    <td>${new Date(log.timestamp).toLocaleTimeString()}</td>
                    <td>${log.ip_address}</td>
                    <td><span class="badge bg-primary">${log.method}</span></td>
                    <td>${log.path}</td>
                    <td><span class="badge ${this.getStatusBadgeClass(log.status_code)}">${log.status_code}</span></td>
                    <td>${log.response_time ? log.response_time + 'ms' : '-'}</td>
                </tr>
            `).join('');
            
            // Update pagination controls - handle missing pagination data
            const pagination = data.pagination;
            if (pagination) {
                this.totalPages = pagination.total_pages; // Store for navigation
                
                const startRecord = ((pagination.current_page - 1) * pagination.limit) + 1;
                const endRecord = Math.min(pagination.current_page * pagination.limit, pagination.total_count);
                
                document.getElementById('pagination-info').textContent = 
                    `Showing ${startRecord} to ${endRecord} of ${pagination.total_count} entries`;
                document.getElementById('current-page-number').textContent = pagination.current_page;
                
                // Update button states
                const firstBtn = document.getElementById('first-page');
                const prevBtn = document.getElementById('prev-page');
                const nextBtn = document.getElementById('next-page');
                const lastBtn = document.getElementById('last-page');
                
                // First and Previous buttons
                if (pagination.has_prev) {
                    firstBtn.classList.remove('disabled');
                    prevBtn.classList.remove('disabled');
                } else {
                    firstBtn.classList.add('disabled');
                    prevBtn.classList.add('disabled');
                }
                
                // Next and Last buttons
                if (pagination.has_next) {
                    nextBtn.classList.remove('disabled');
                    lastBtn.classList.remove('disabled');
                } else {
                    nextBtn.classList.add('disabled');
                    lastBtn.classList.add('disabled');
                }
                
                // Update goto page input max value and placeholder
                const gotoInput = document.getElementById('goto-page');
                gotoInput.max = pagination.total_pages;
                gotoInput.placeholder = `1-${pagination.total_pages}`;
                
                // Update records per page selector to match current setting
                document.getElementById('records-per-page').value = this.logsPerPage;
                
                // Show/hide pagination
                document.getElementById('logs-pagination').style.display = 
                    pagination.total_pages > 1 ? 'block' : 'none';
            } else {
                // Hide pagination if no pagination data
                document.getElementById('logs-pagination').style.display = 'none';
                console.warn('No pagination data received from API');
            }
            
        } catch (error) {
            console.error('Error loading recent logs:', error);
            // Show error message in table
            const tbody = document.getElementById('recent-logs-table');
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center text-danger">
                        <i class="bi bi-exclamation-triangle"></i> Error loading logs: ${error.message}
                    </td>
                </tr>
            `;
        }
    }

    updateTopIPs(topIPs) {
        const container = document.getElementById('top-ips-list');
        container.innerHTML = topIPs.map((ip, index) => `
            <div class="d-flex justify-content-between align-items-center mb-2">
                <span>${ip.ip_address}</span>
                <span class="badge bg-secondary">${ip.count}</span>
            </div>
        `).join('');
    }

    async initCharts() {
        // Status codes chart
        const statusCtx = document.getElementById('status-codes-chart').getContext('2d');
        this.charts.statusCodes = new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: [],
                datasets: [{
                    data: [],
                    backgroundColor: ['#28a745', '#ffc107', '#dc3545', '#6c757d']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });

        // Error trends chart
        const trendsResponse = await fetch('/api/error-trends');
        const trendsData = await trendsResponse.json();
        
        const trendsCtx = document.getElementById('error-trends-chart').getContext('2d');
        this.charts.errorTrends = new Chart(trendsCtx, {
            type: 'line',
            data: {
                labels: trendsData.trends.map(t => new Date(t.hour).toLocaleTimeString()),
                datasets: [{
                    label: 'Total Requests',
                    data: trendsData.trends.map(t => t.total_requests),
                    borderColor: '#007bff',
                    backgroundColor: 'rgba(0, 123, 255, 0.1)'
                }, {
                    label: 'Errors',
                    data: trendsData.trends.map(t => t.errors),
                    borderColor: '#dc3545',
                    backgroundColor: 'rgba(220, 53, 69, 0.1)'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    updateStatusCodesChart(statusCodes) {
        if (this.charts.statusCodes) {
            this.charts.statusCodes.data.labels = statusCodes.map(s => s.status_code);
            this.charts.statusCodes.data.datasets[0].data = statusCodes.map(s => s.count);
            this.charts.statusCodes.update();
        }
    }

    getStatusBadgeClass(statusCode) {
        if (statusCode >= 200 && statusCode < 300) return 'bg-success';
        if (statusCode >= 300 && statusCode < 400) return 'bg-info';
        if (statusCode >= 400 && statusCode < 500) return 'bg-warning';
        if (statusCode >= 500) return 'bg-danger';
        return 'bg-secondary';
    }
}

// Initialize dashboard when page loads
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new LogDashboard();
});
</script>

</&> 