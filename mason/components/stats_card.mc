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
% } elsif ($icon eq 'time') {
            <i class="bi bi-stopwatch-fill text-info" style="font-size: 3rem;"></i>
% } elsif ($icon eq 'status') {
            <i class="bi bi-check-circle-fill text-success" style="font-size: 3rem;"></i>
% } else {
            <i class="bi bi-graph-up" style="font-size: 3rem;"></i>
% }
        </div>
        <h5 class="card-title text-muted"><% $title %></h5>
        <p class="card-text display-6"><% $value %></p>
    </div>
</div> 