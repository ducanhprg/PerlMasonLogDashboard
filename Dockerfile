FROM perl:5.32-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy cpanfile and install dependencies
COPY cpanfile* ./
RUN cpanm --installdeps .

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/logs /app/data /tmp/mason_data

# Set environment variables
ENV PERL5LIB=/app/lib
ENV MASON_COMP_ROOT=/app/mason
ENV MASON_DATA_DIR=/tmp/mason_data

# Expose port
EXPOSE 5000

# Start the application with plackup
CMD ["plackup", "-p", "5000", "--host", "0.0.0.0", "bin/app.pl"] 