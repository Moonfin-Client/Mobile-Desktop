#!/bin/bash
#
# test_runner.sh
#
# Script to run RAR plugin tests on various platforms.
# Usage: ./test_runner.sh [platform]
#
# Platforms: unit, linux, macos, windows, android, ios, web, all
#
# Prerequisites:
#   - Flutter SDK installed and in PATH
#   - For desktop: libarchive installed (see README.md)
#   - For mobile: emulator/device connected
#   - For web: Chrome installed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

run_unit_tests() {
    print_header "Running Unit Tests"

    echo "Running plugin unit tests..."
    flutter test test/ --reporter expanded || {
        print_error "Unit tests failed"
        return 1
    }

    print_success "Unit tests passed"
}

run_macos_tests() {
    print_header "Running macOS Integration Tests"

    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "Skipping macOS tests (not on macOS)"
        return 0
    fi

    # Check for libarchive
    if ! brew list libarchive &>/dev/null; then
        print_warning "libarchive not found. Install with: brew install libarchive"
    fi

    echo "Building macOS example app..."
    cd example
    flutter build macos || {
        print_error "macOS build failed"
        cd ..
        return 1
    }

    echo "Running macOS integration tests..."
    flutter test integration_test/rar_integration_test.dart -d macos || {
        print_error "macOS integration tests failed"
        cd ..
        return 1
    }

    cd ..
    print_success "macOS tests passed"
}

run_android_tests() {
    print_header "Running Android Integration Tests"

    # Check for connected Android device/emulator
    if ! flutter devices | grep -q android; then
        print_warning "No Android device found. Skipping Android tests."
        return 0
    fi

    echo "Running Android integration tests..."
    cd example
    flutter test integration_test/rar_integration_test.dart -d android || {
        print_error "Android integration tests failed"
        cd ..
        return 1
    }

    cd ..
    print_success "Android tests passed"
}

run_ios_tests() {
    print_header "Running iOS Integration Tests"

    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "Skipping iOS tests (not on macOS)"
        return 0
    fi

    # Check for iOS simulator
    if ! flutter devices | grep -q -i "iphone\|ipad"; then
        print_warning "No iOS device/simulator found. Skipping iOS tests."
        return 0
    fi

    echo "Running iOS integration tests..."
    cd example
    flutter test integration_test/rar_integration_test.dart -d ios || {
        print_error "iOS integration tests failed"
        cd ..
        return 1
    }

    cd ..
    print_success "iOS tests passed"
}

run_web_tests() {
    print_header "Running Web Integration Tests"

    echo "Running Web integration tests..."
    cd example
    flutter test integration_test/rar_integration_test.dart -d chrome --headless || {
        print_error "Web integration tests failed"
        cd ..
        return 1
    }

    cd ..
    print_success "Web tests passed"
}

show_usage() {
    echo "Usage: $0 [platform]"
    echo ""
    echo "Platforms:"
    echo "  unit      - Run unit tests only"
    echo "  macos     - Run macOS desktop tests"
    echo "  android   - Run Android tests"
    echo "  ios       - Run iOS tests"
    echo "  web       - Run Web tests"
    echo "  desktop   - Run desktop tests (macos)"
    echo "  mobile    - Run all mobile tests (android, ios)"
    echo "  all       - Run all tests"
    echo ""
    echo "Examples:"
    echo "  $0 unit      # Run unit tests"
    echo "  $0 macos     # Run macOS integration tests"
    echo "  $0 all       # Run all tests"
}

# Main script
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

case "$1" in
    unit)
        run_unit_tests
        ;;
    macos)
        run_unit_tests
        run_macos_tests
        ;;
    android)
        run_unit_tests
        run_android_tests
        ;;
    ios)
        run_unit_tests
        run_ios_tests
        ;;
    web)
        run_unit_tests
        run_web_tests
        ;;
    desktop)
        run_unit_tests
        run_macos_tests
        ;;
    mobile)
        run_unit_tests
        run_android_tests
        run_ios_tests
        ;;
    all)
        run_unit_tests
        run_macos_tests
        run_android_tests
        run_ios_tests
        run_web_tests
        ;;
    *)
        print_error "Unknown platform: $1"
        show_usage
        exit 1
        ;;
esac

print_header "Test Summary"
print_success "All requested tests completed!"
