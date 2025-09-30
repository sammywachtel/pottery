#!/bin/bash

# Test script for Firebase Authentication migration verification
# This script runs comprehensive tests to validate the Firebase migration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Opening move: check environment and dependencies
echo -e "${BLUE}🚀 Firebase Authentication Migration Test Suite${NC}"
echo "=============================================="

# Check if we're in the right directory
if [ ! -f "backend/requirements.txt" ]; then
    echo -e "${RED}❌ Error: Run this script from the project root directory${NC}"
    exit 1
fi

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

# Track overall test results
BACKEND_UNIT_TESTS=1
BACKEND_INTEGRATION_TESTS=1
FLUTTER_TESTS=1
OVERALL_SUCCESS=0

# Main play: run backend tests
print_section "🐍 Backend Firebase Authentication Tests"

cd backend

# Check if required environment variables are set
if [ -f ".env.test" ]; then
    echo -e "${GREEN}✅ Found .env.test file${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: .env.test file not found${NC}"
    echo "Some integration tests may fail without proper configuration"
fi

# Install dependencies if needed
echo "📦 Checking Python dependencies..."
pip install -r requirements.txt > /dev/null 2>&1
echo -e "${GREEN}✅ Dependencies installed${NC}"

# Run Firebase core unit tests
echo ""
echo "🧪 Running Firebase core module tests..."
if python -m pytest tests/test_firebase_core.py -v; then
    print_result 0 "Firebase core module tests passed"
else
    print_result 1 "Firebase core module tests failed"
    BACKEND_UNIT_TESTS=0
fi

# Run Firebase authentication unit tests
echo ""
echo "🧪 Running Firebase authentication unit tests..."
if python -m pytest tests/test_auth_firebase.py -v; then
    print_result 0 "Firebase authentication unit tests passed"
else
    print_result 1 "Firebase authentication unit tests failed"
    BACKEND_UNIT_TESTS=0
fi

# Run user profile service tests
echo ""
echo "🧪 Running user profile service tests..."
if python -m pytest tests/test_user_profile_service.py -v; then
    print_result 0 "User profile service tests passed"
else
    print_result 1 "User profile service tests failed"
    BACKEND_UNIT_TESTS=0
fi

# Run migration verification tests
echo ""
echo "🧪 Running migration verification tests..."
if python -m pytest tests/test_migration_verification.py -v; then
    print_result 0 "Migration verification tests passed"
else
    print_result 1 "Migration verification tests failed"
    BACKEND_UNIT_TESTS=0
fi

# Run Firebase integration tests
echo ""
echo "🧪 Running Firebase integration tests..."
if python -m pytest tests/integration/test_firebase_auth_integration.py -v -m integration; then
    print_result 0 "Firebase integration tests passed"
else
    print_result 1 "Firebase integration tests failed"
    BACKEND_INTEGRATION_TESTS=0
fi

# Run all Firebase-related tests together
echo ""
echo "🧪 Running comprehensive Firebase test suite..."
if python -m pytest tests/test_firebase_core.py tests/test_auth_firebase.py tests/test_user_profile_service.py tests/test_migration_verification.py tests/integration/test_firebase_auth_integration.py -v; then
    print_result 0 "Comprehensive Firebase test suite passed"
else
    print_result 1 "Some Firebase tests failed"
fi

cd ..

# Big play: run Flutter tests
print_section "📱 Flutter Firebase Authentication Tests"

cd frontend

# Check Flutter environment
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    FLUTTER_TESTS=0
else
    echo -e "${GREEN}✅ Flutter environment detected${NC}"

    # Get dependencies
    echo "📦 Getting Flutter dependencies..."
    if flutter pub get > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
    else
        echo -e "${RED}❌ Failed to get Flutter dependencies${NC}"
        FLUTTER_TESTS=0
    fi

    if [ $FLUTTER_TESTS -eq 1 ]; then
        # Run Firebase repository tests
        echo ""
        echo "🧪 Running Firebase authentication repository tests..."
        if flutter test test/repositories/firebase_auth_repository_test.dart; then
            print_result 0 "Firebase auth repository tests passed"
        else
            print_result 1 "Firebase auth repository tests failed"
            FLUTTER_TESTS=0
        fi

        # Run Firebase login widget tests
        echo ""
        echo "🧪 Running Firebase login screen widget tests..."
        if flutter test test/widgets/firebase_login_screen_test.dart; then
            print_result 0 "Firebase login screen tests passed"
        else
            print_result 1 "Firebase login screen tests failed"
            FLUTTER_TESTS=0
        fi

        # Run API client tests
        echo ""
        echo "🧪 Running Firebase API client integration tests..."
        if flutter test test/services/firebase_api_client_test.dart; then
            print_result 0 "Firebase API client tests passed"
        else
            print_result 1 "Firebase API client tests failed"
            FLUTTER_TESTS=0
        fi

        # Run existing auth state tests (updated for Firebase)
        echo ""
        echo "🧪 Running updated auth state tests..."
        if flutter test test/auth_state_test.dart; then
            print_result 0 "Auth state tests passed"
        else
            print_result 1 "Auth state tests failed"
            FLUTTER_TESTS=0
        fi

        # Run all Flutter tests together
        echo ""
        echo "🧪 Running comprehensive Flutter test suite..."
        if flutter test test/repositories/firebase_auth_repository_test.dart test/widgets/firebase_login_screen_test.dart test/services/firebase_api_client_test.dart test/auth_state_test.dart; then
            print_result 0 "Comprehensive Flutter test suite passed"
        else
            print_result 1 "Some Flutter tests failed"
        fi
    fi
fi

cd ..

# Victory lap: generate test report
print_section "📊 Firebase Migration Test Results Summary"

echo "Backend Unit Tests:       $([ $BACKEND_UNIT_TESTS -eq 1 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo "Backend Integration Tests: $([ $BACKEND_INTEGRATION_TESTS -eq 1 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo "Flutter Tests:            $([ $FLUTTER_TESTS -eq 1 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"

# Determine overall success
if [ $BACKEND_UNIT_TESTS -eq 1 ] && [ $BACKEND_INTEGRATION_TESTS -eq 1 ] && [ $FLUTTER_TESTS -eq 1 ]; then
    OVERALL_SUCCESS=1
    echo ""
    echo -e "${GREEN}🎉 ALL FIREBASE MIGRATION TESTS PASSED!${NC}"
    echo -e "${GREEN}✅ The Firebase authentication migration is ready for deployment${NC}"
else
    echo ""
    echo -e "${RED}❌ SOME FIREBASE MIGRATION TESTS FAILED${NC}"
    echo -e "${RED}🔧 Please fix failing tests before proceeding with migration${NC}"
fi

# Additional verification reminders
print_section "🔍 Migration Verification Checklist"

echo "Manual verification steps to complete:"
echo "☐ Firebase project configured with required auth providers"
echo "☐ Firebase Admin SDK service account key generated"
echo "☐ Environment variables set in .env files"
echo "☐ Legacy admin user migrated to Firebase"
echo "☐ Test admin login with Firebase credentials"
echo "☐ Verify existing pottery data remains accessible"
echo "☐ Test photo upload with Firebase authentication"
echo "☐ Test user profile synchronization"
echo "☐ Verify error handling and edge cases"
echo "☐ Performance testing with Firebase tokens"

echo ""
echo -e "${BLUE}📚 Documentation Updates Needed:${NC}"
echo "☐ Update README with Firebase setup instructions"
echo "☐ Update API documentation with Firebase auth examples"
echo "☐ Create migration guide for other developers"
echo "☐ Update environment variable documentation"

echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
if [ $OVERALL_SUCCESS -eq 1 ]; then
    echo "1. Complete manual verification checklist"
    echo "2. Update documentation"
    echo "3. Deploy to staging environment for end-to-end testing"
    echo "4. Monitor Firebase Auth dashboard for issues"
    echo "5. Plan production migration timeline"
else
    echo "1. Review and fix failing tests"
    echo "2. Re-run this test suite until all tests pass"
    echo "3. Investigate any mock vs real Firebase behavior differences"
    echo "4. Ensure all error scenarios are properly handled"
fi

# Exit with appropriate code
exit $([ $OVERALL_SUCCESS -eq 1 ] && echo 0 || echo 1)
