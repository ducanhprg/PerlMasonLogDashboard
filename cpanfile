# Core web framework
requires 'Plack', '1.0047';
requires 'Plack::Request';
requires 'Plack::Response';
requires 'Plack::Builder';
requires 'Plack::Middleware::Static';

# Mason templating
requires 'HTML::Mason', '1.58';
requires 'HTML::Mason::PSGIHandler';

# Database
requires 'DBI', '1.643';
requires 'DBD::Pg', '3.14.2';

# JSON handling
requires 'JSON::XS', '4.03';

# Date/Time
requires 'DateTime', '1.54';
requires 'DateTime::Format::Strptime', '1.78';

# Core modules (might be missing in slim images)
requires 'FindBin';
requires 'Carp';
requires 'Encode';

# Testing
requires 'Test::More', '1.302175';
requires 'Test::Exception', '0.43'; 