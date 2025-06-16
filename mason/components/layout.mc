<%args>
$title => 'Log Dashboard'
</%args>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><% $title %></title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <style>
        html, body {
            height: 100%;
        }
        body {
            background-color: #f8f9fa;
            display: flex;
            flex-direction: column;
        }
        .card {
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            border: 1px solid rgba(0, 0, 0, 0.125);
        }
        .stats-card {
            text-align: center;
            padding: 1.5rem;
        }
        .stats-card .display-6 {
            font-weight: bold;
            margin-bottom: 0.5rem;
        }
        .chart-container {
            position: relative;
            height: 300px;
        }
        .table th {
            border-top: none;
            font-weight: 600;
            color: #495057;
        }
        .badge {
            font-size: 0.75em;
        }
        .stats-icon {
            font-size: 3rem;
            margin-bottom: 0.5rem;
        }
        main {
            flex: 1;
        }
        footer {
            margin-top: auto;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="/">
                <i class="bi bi-bar-chart-line-fill"></i> Log Dashboard
            </a>
            <div class="navbar-nav ms-auto">
                <span class="navbar-text">
                    Perl + Mason + PostgreSQL Demo
                </span>
            </div>
        </div>
    </nav>

    <main class="py-4">
        <% $m->content %>
    </main>

    <footer class="bg-dark text-light py-3">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-6">
                    <small>
                        Powered by <strong>Perl</strong>, <strong>Mason</strong>, and <strong>PostgreSQL</strong>
                    </small>
                </div>
                <div class="col-md-6 text-end">
                    <small>
                        Demonstrating text processing, templating, and database analytics
                    </small>
                </div>
            </div>
        </div>
    </footer>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html> 