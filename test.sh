#!/bin/bash

# Test script for Claude Code SDK Container
# This helps verify everything is working correctly

set -e

echo "Testing Claude Code SDK Container..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    echo "Create .env file first: cp .env.example .env"
    exit 1
fi

# Load env vars safely
set -a
source .env
set +a

# Check if tokens are set
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "Error: CLAUDE_CODE_OAUTH_TOKEN not set in .env"
    exit 1
fi

echo "Environment loaded"

if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker."
    exit 1
fi

if ! docker images | grep -q "claude-code-sdk"; then
    echo "Building Docker image..."
    docker build -t claude-code-sdk . || exit 1
fi

if ! docker ps | grep -q claude-code-sdk-container; then
    docker ps -a | grep -q claude-code-sdk-container && docker rm claude-code-sdk-container > /dev/null 2>&1
    echo "Starting container..."
    docker run -d --name claude-code-sdk-container -p 8080:8080 --env-file .env claude-code-sdk || exit 1
    sleep 3
fi

echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health 2>/dev/null || echo "FAILED")

if [[ "$HEALTH_RESPONSE" == "FAILED" ]]; then
    echo "Health check failed"
    exit 1
fi

if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    echo "Health check passed"
else
    echo "Health check unhealthy - check CLAUDE_CODE_OAUTH_TOKEN"
fi

echo "Testing query endpoint..."
if [ -n "$CLAUDE_CODE_SDK_CONTAINER_API_KEY" ]; then
    QUERY_RESPONSE=$(curl -s -X POST http://localhost:8080/query \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $CLAUDE_CODE_SDK_CONTAINER_API_KEY" \
        -d '{"prompt": "Say hello in 3 words"}' 2>/dev/null || echo "FAILED")
else
    QUERY_RESPONSE=$(curl -s -X POST http://localhost:8080/query \
        -H "Content-Type: application/json" \
        -d '{"prompt": "Say hello in 3 words"}' 2>/dev/null || echo "FAILED")
fi

if [[ "$QUERY_RESPONSE" == "FAILED" ]]; then
    echo "Query failed"
    exit 1
elif echo "$QUERY_RESPONSE" | grep -q '"success":true'; then
    echo "Query successful"
else
    echo "Query failed: $QUERY_RESPONSE"
    exit 1
fi

echo "All tests passed!"
echo "Web CLI: http://localhost:8080"
echo "API: POST http://localhost:8080/query"