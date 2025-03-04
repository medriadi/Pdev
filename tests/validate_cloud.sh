#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Validating cloud tools installations..."

# Test AWS CLI
test_aws() {
    if command_exists "aws"; then
        if aws --version && \
           aws sts get-caller-identity 2>/dev/null; then
            log_info "AWS CLI: OK"
            
            # Test AWS CDK if installed
            if command_exists "cdk"; then
                if cdk --version; then
                    log_info "AWS CDK: OK"
                fi
            fi
            
            # Test AWS SAM if installed
            if command_exists "sam"; then
                if sam --version; then
                    log_info "AWS SAM: OK"
                fi
            fi
            
            return 0
        fi
    fi
    log_error "AWS CLI validation failed"
    return 1
}

# Test Azure CLI
test_azure() {
    if command_exists "az"; then
        if az --version && \
           az account list 2>/dev/null; then
            log_info "Azure CLI: OK"
            
            # Test Azure Functions Core Tools if installed
            if command_exists "func"; then
                if func --version; then
                    log_info "Azure Functions Core Tools: OK"
                fi
            fi
            
            return 0
        fi
    fi
    log_error "Azure CLI validation failed"
    return 1
}

# Test Google Cloud SDK
test_gcloud() {
    if command_exists "gcloud"; then
        if gcloud --version && \
           gcloud auth list 2>/dev/null; then
            log_info "Google Cloud SDK: OK"
            
            # Test additional components
            if gcloud components list --format="table(id,state.name)" 2>/dev/null | grep -q "installed"; then
                log_info "GCloud components: OK"
            fi
            
            return 0
        fi
    fi
    log_error "Google Cloud SDK validation failed"
    return 1
}

# Test Digital Ocean CLI
test_doctl() {
    if command_exists "doctl"; then
        if doctl version && \
           doctl account get 2>/dev/null; then
            log_info "Digital Ocean CLI: OK"
            return 0
        fi
    fi
    log_error "Digital Ocean CLI validation failed"
    return 1
}

# Test Serverless Framework
test_serverless() {
    if command_exists "serverless" || command_exists "sls"; then
        if serverless --version 2>/dev/null || sls --version 2>/dev/null; then
            log_info "Serverless Framework: OK"
            return 0
        fi
    fi
    log_error "Serverless Framework validation failed"
    return 1
}

# Test Pulumi
test_pulumi() {
    if command_exists "pulumi"; then
        if pulumi version; then
            log_info "Pulumi: OK"
            return 0
        fi
    fi
    log_error "Pulumi validation failed"
    return 1
}

# Test cloud development tools
test_cloud_tools() {
    local tools_ok=true
    
    # Test CloudFormation linter
    if ! command_exists "cfn-lint"; then
        log_error "CloudFormation linter not found"
        tools_ok=false
    fi
    
    if [ "$tools_ok" = true ]; then
        log_info "Cloud development tools: OK"
        return 0
    fi
    
    return 1
}

# Run all tests based on configuration
DEFAULT_CLOUD=$(get_config_value "DEFAULT_CLOUD" "aws")
INSTALL_MULTIPLE=$(get_config_value "INSTALL_MULTIPLE_CLOUDS" "true")

# Always test the default cloud provider
case $DEFAULT_CLOUD in
    "aws")
        test_aws
        ;;
    "azure")
        test_azure
        ;;
    "gcloud")
        test_gcloud
        ;;
esac

# Test additional providers if configured
if [ "$INSTALL_MULTIPLE" = "true" ]; then
    case $DEFAULT_CLOUD in
        "aws")
            test_azure
            test_gcloud
            ;;
        "azure")
            test_aws
            test_gcloud
            ;;
        "gcloud")
            test_aws
            test_azure
            ;;
    esac
    
    test_doctl
fi

# Test common cloud tools
test_serverless
test_pulumi
test_cloud_tools