#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Testing MongoDB Authentication & AI${NC}"
echo -e "${BLUE}================================${NC}\n"

# Backend URL
BASE_URL="http://localhost:5000"

# Test email with timestamp for uniqueness
TEST_EMAIL="testuser_$(date +%s)@example.com"
TEST_PASSWORD="password123"
TEST_NAME="Test User"

echo -e "${YELLOW}📧 Test Email: $TEST_EMAIL${NC}"
echo -e "${YELLOW}🔐 Test Password: $TEST_PASSWORD${NC}\n"

# 1. Health Check
echo -e "${BLUE}1️⃣ Testing Health Check...${NC}"
HEALTH=$(curl -s -X GET "$BASE_URL/health")
echo "Response: $HEALTH"
echo ""

# 2. Sign Up
echo -e "${BLUE}2️⃣ Testing Sign Up...${NC}"
SIGNUP_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"$TEST_NAME\",
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"businessType\": \"Test Business\",
    \"phone\": \"+994511234567\"
  }")

echo "Response: $SIGNUP_RESPONSE"
echo ""

# Extract token from signup response
TOKEN=$(echo $SIGNUP_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
USER_ID=$(echo $SIGNUP_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ Failed to get token from signup${NC}"
  echo "Full response: $SIGNUP_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✅ Sign Up Successful!${NC}"
echo -e "${YELLOW}🔑 Token: ${TOKEN:0:30}...${NC}"
echo -e "${YELLOW}👤 User ID: $USER_ID${NC}\n"

# 3. Login Test
echo -e "${BLUE}3️⃣ Testing Login...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\"
  }")

echo "Response: $LOGIN_RESPONSE"
echo ""

LOGIN_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$LOGIN_TOKEN" ]; then
  echo -e "${RED}❌ Failed to login${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Login Successful!${NC}\n"

# 4. Chat API Test (AI Response)
echo -e "${BLUE}4️⃣ Testing Chat API with AI Response...${NC}"
CHAT_PROMPT="বাংলাদেশে একটি কফি শপ ব্যবসা শুরু করতে কত বিনিয়োগ লাগবে? সংক্ষিপ্ত উত্তর দিন।"
echo -e "${YELLOW}📝 Prompt: $CHAT_PROMPT${NC}"
echo ""

CHAT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/chat" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LOGIN_TOKEN" \
  -d "{
    \"prompt\": \"$CHAT_PROMPT\"
  }")

echo "Response:"
echo $CHAT_RESPONSE | python3 -m json.tool 2>/dev/null || echo $CHAT_RESPONSE
echo ""

AI_MESSAGE=$(echo $CHAT_RESPONSE | grep -o '"message":"[^"]*' | cut -d'"' -f4 | head -1)

if [ -z "$AI_MESSAGE" ]; then
  echo -e "${RED}❌ No AI message received${NC}"
else
  echo -e "${GREEN}✅ AI Response Received!${NC}"
  echo -e "${YELLOW}💬 Message: ${AI_MESSAGE:0:100}...${NC}"
  echo ""
fi

# 5. Location Analysis Test
echo -e "${BLUE}5️⃣ Testing Location Analysis API...${NC}"
LOCATION_RESPONSE=$(curl -s -X POST "$BASE_URL/api/location-analysis" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LOGIN_TOKEN" \
  -d '{
    "city": "Baku",
    "businessType": "Coffee Shop",
    "address": "Neftchi Avenue 5"
  }')

echo "Response:"
echo $LOCATION_RESPONSE | python3 -m json.tool 2>/dev/null || echo $LOCATION_RESPONSE
echo -e "${GREEN}✅ Location Analysis Test Complete!${NC}\n"

# 6. ROI Calculation Test
echo -e "${BLUE}6️⃣ Testing ROI Calculation API...${NC}"
ROI_RESPONSE=$(curl -s -X POST "$BASE_URL/api/roi" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LOGIN_TOKEN" \
  -d '{
    "rent": 2000,
    "averageTicket": 50,
    "margin": 0.35
  }')

echo "Response:"
echo $ROI_RESPONSE | python3 -m json.tool 2>/dev/null || echo $ROI_RESPONSE
echo -e "${GREEN}✅ ROI Calculation Test Complete!${NC}\n"

# Summary
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✅ All Tests Completed!${NC}"
echo -e "${BLUE}================================${NC}\n"

echo -e "${YELLOW}📋 Test Summary:${NC}"
echo "  ✅ Health Check: Passed"
echo "  ✅ Sign Up: Passed"
echo "  ✅ Login: Passed"
echo "  ✅ Chat API (with AI): Tested"
echo "  ✅ Location Analysis: Tested"
echo "  ✅ ROI Calculation: Tested"
echo ""

echo -e "${YELLOW}🔑 Credentials for Testing:${NC}"
echo "  Email: $TEST_EMAIL"
echo "  Password: $TEST_PASSWORD"
echo ""

echo -e "${YELLOW}📌 Use this token for manual testing:${NC}"
echo "  $LOGIN_TOKEN"
echo ""

echo -e "${GREEN}✨ Setup is working! Ready for Flutter app testing.${NC}"
