#!/bin/bash

set -e

echo "🚀 Setting up Perl Mason PostgreSQL Log Dashboard Demo..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs data

# Build and start services
echo "🐳 Building and starting Docker services..."
docker compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# Generate sample logs and populate database
echo "📝 Generating sample log data and populating database..."
docker compose exec app perl bin/generate_sample_logs.pl

# Check if services are running
if docker compose ps | grep -q "Up"; then
    echo "✅ Services are running!"
    echo ""
    echo "🎉 Setup complete! You can now access:"
    echo "   📊 Dashboard: http://localhost:5000"
    echo "   🗄️  Database: localhost:5432 (postgres/postgres)"
    echo ""
    echo "📈 The dashboard showcases:"
    echo "   • Perl's advanced regex parsing"
    echo "   • Mason's component-based templating"
    echo "   • PostgreSQL's analytical queries"
    echo ""
    echo "🔧 Useful commands:"
    echo "   View logs: docker compose logs -f app"
    echo "   Run tests: docker compose exec app prove test/integration/"
    echo "   Stop demo: docker compose down"
else
    echo "❌ Some services failed to start. Check logs with: docker compose logs"
    exit 1
fi 