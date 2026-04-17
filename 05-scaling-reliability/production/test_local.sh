#!/bin/bash
# Test script cho production app (local mode, không cần Docker)

echo "=========================================="
echo "Testing Production App (Local Mode)"
echo "=========================================="
echo ""

BASE_URL="http://localhost:8000"

echo "1. Testing Health Check..."
curl -s $BASE_URL/health | python3 -m json.tool
echo ""

echo "2. Testing Readiness Check..."
curl -s $BASE_URL/ready | python3 -m json.tool
echo ""

echo "3. Testing Chat (Create Session)..."
RESPONSE=$(curl -s -X POST $BASE_URL/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "What is Docker?"}')
echo $RESPONSE | python3 -m json.tool

SESSION_ID=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['session_id'])")
echo ""
echo "Session ID: $SESSION_ID"
echo ""

echo "4. Testing Multi-turn Conversation..."
curl -s -X POST $BASE_URL/chat \
  -H "Content-Type: application/json" \
  -d "{\"question\": \"Why do we need it?\", \"session_id\": \"$SESSION_ID\"}" | python3 -m json.tool
echo ""

echo "5. Testing Another Turn..."
curl -s -X POST $BASE_URL/chat \
  -H "Content-Type: application/json" \
  -d "{\"question\": \"What is Kubernetes?\", \"session_id\": \"$SESSION_ID\"}" | python3 -m json.tool
echo ""

echo "6. Testing History Endpoint..."
curl -s $BASE_URL/chat/$SESSION_ID/history | python3 -m json.tool
echo ""

echo "7. Testing Delete Session..."
curl -s -X DELETE $BASE_URL/chat/$SESSION_ID | python3 -m json.tool
echo ""

echo "=========================================="
echo "✅ All tests completed!"
echo "=========================================="
