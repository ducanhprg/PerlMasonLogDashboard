<%args>
$title
$chart_id
$chart_type => 'line'
$height => '300px'
$loading => 0
$error => ''
</%args>

<div class="card">
    <div class="card-header">
        <h5 class="card-title mb-0"><% $title %></h5>
        <div class="chart-controls">
            <button class="btn btn-sm" onclick="refreshChart('<% $chart_id %>')">
                <i class="icon-refresh"></i> Refresh
            </button>
            <button class="btn btn-sm" onclick="exportChart('<% $chart_id %>')">
                <i class="icon-download"></i> Export
            </button>
        </div>
    </div>
    <div class="card-body">
        <div class="chart-container">
% if ($loading) {
            <div class="chart-loading">
                <div class="spinner"></div>
                <p>Loading chart data...</p>
            </div>
% } elsif ($error) {
            <div class="chart-error">
                <i class="icon-error"></i>
                <p>Error loading chart: <% $error %></p>
                <button class="btn btn-primary" onclick="retryChart('<% $chart_id %>')">
                    Retry
                </button>
            </div>
% } else {
            <canvas id="<% $chart_id %>" data-chart-type="<% $chart_type %>"></canvas>
% }
        </div>
    </div>
</div> 