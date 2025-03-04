#!/bin/bash

source "$(dirname "$0")/common.sh"

print_header() {
    echo "======================================"
    echo "     PDev Environment Test Suite"
    echo "======================================"
    echo
}

# Initialize test results
declare -A test_results
TEST_DIR="$(dirname "$0")/tests"
REPORT_DIR="/opt/pdev/test_reports"
REPORT_FILE="$REPORT_DIR/test_report_$(date +%Y%m%d_%H%M%S).txt"

# Ensure report directory exists
ensure_dir "$REPORT_DIR"

# Run all validation tests
run_all_tests() {
    local start_time=$(date +%s)
    
    {
        print_header
        echo "Test Report Generated: $(date)"
        echo "System Information:"
        echo "  OS: $(detect_distro)"
        echo "  Kernel: $(uname -r)"
        echo "  Architecture: $(uname -m)"
        echo
        echo "=== Test Results ==="
        echo
        
        # Run language tests
        echo "Programming Languages Tests:"
        echo "-------------------------"
        if bash "$TEST_DIR/validate_languages.sh"; then
            test_results["languages"]="PASS"
        else
            test_results["languages"]="FAIL"
        fi
        echo
        
        # Run database tests
        echo "Database Tests:"
        echo "-------------"
        if bash "$TEST_DIR/validate_databases.sh"; then
            test_results["databases"]="PASS"
        else
            test_results["databases"]="FAIL"
        fi
        echo
        
        # Run container tests
        echo "Container Tools Tests:"
        echo "-------------------"
        if bash "$TEST_DIR/validate_containers.sh"; then
            test_results["containers"]="PASS"
        else
            test_results["containers"]="FAIL"
        fi
        echo
        
        # Run cloud tests
        echo "Cloud Tools Tests:"
        echo "---------------"
        if bash "$TEST_DIR/validate_cloud.sh"; then
            test_results["cloud"]="PASS"
        else
            test_results["cloud"]="FAIL"
        fi
        echo
        
        # Run DevOps tests
        echo "DevOps Tools Tests:"
        echo "----------------"
        if bash "$TEST_DIR/validate_devops.sh"; then
            test_results["devops"]="PASS"
        else
            test_results["devops"]="FAIL"
        fi
        echo
        
        # Run editor tests
        echo "Editor Tests:"
        echo "------------"
        if bash "$TEST_DIR/validate_editors.sh"; then
            test_results["editors"]="PASS"
        else
            test_results["editors"]="FAIL"
        fi
        echo

        # Run editor plugins tests
        echo "Editor Plugins Tests:"
        echo "------------------"
        if bash "$TEST_DIR/validate_editor_plugins.sh"; then
            test_results["editor_plugins"]="PASS"
        else
            test_results["editor_plugins"]="FAIL"
        fi
        echo

        # Run backup validation tests
        echo "Backup Validation Tests:"
        echo "---------------------"
        if bash "$TEST_DIR/validate_backup.sh"; then
            test_results["backup"]="PASS"
        else
            test_results["backup"]="FAIL"
        fi
        echo
        
        # Calculate test summary
        local total_tests=${#test_results[@]}
        local passed_tests=0
        
        echo "=== Test Summary ==="
        echo
        printf "%-20s | %s\n" "Category" "Status"
        echo "--------------------+--------"
        for category in "${!test_results[@]}"; do
            printf "%-20s | %s\n" "$category" "${test_results[$category]}"
            if [ "${test_results[$category]}" = "PASS" ]; then
                ((passed_tests++))
            fi
        done
        echo
        
        # Calculate success rate
        local success_rate=$(( (passed_tests * 100) / total_tests ))
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo "Test Statistics:"
        echo "--------------"
        echo "Total Tests: $total_tests"
        echo "Passed: $passed_tests"
        echo "Failed: $((total_tests - passed_tests))"
        echo "Success Rate: ${success_rate}%"
        echo "Total Duration: ${duration} seconds"
        
    } | tee "$REPORT_FILE"
    
    log_info "Test report saved to: $REPORT_FILE"
    
    # Return overall success/failure
    return $((total_tests - passed_tests))
}

# Main execution
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run with sudo"
    exit 1
fi

run_all_tests
exit_code=$?

if [ $exit_code -eq 0 ]; then
    log_info "All tests passed successfully!"
else
    log_error "Some tests failed. Please check the report for details."
fi

exit $exit_code