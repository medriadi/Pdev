#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Installing Cloud Development Tools..."

# Update package manager
update_pkg_manager

# AWS CLI installation
install_aws() {
    if ! command_exists "aws"; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        rm -rf aws awscliv2.zip
        
        # Install AWS CDK if development tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            npm install -g aws-cdk
        fi
        
        # Install AWS SAM CLI if development tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            curl -Lo aws-sam.zip https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
            unzip aws-sam.zip -d sam-installation
            ./sam-installation/install
            rm -rf sam-installation aws-sam.zip
        fi
        
        # Install Session Manager plugin
        curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
        dpkg -i session-manager-plugin.deb
        rm session-manager-plugin.deb
    fi
}

# Azure CLI installation
install_azure() {
    if ! command_exists "az"; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash
        
        # Install Azure Functions Core Tools if development tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
            mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
            echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-functions.list
            update_pkg_manager
            install_package "azure-functions-core-tools-4"
        fi
        
        # Install Azure Static Web Apps CLI if development tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            npm install -g @azure/static-web-apps-cli
        fi
    fi
}

# Google Cloud SDK installation
install_gcloud() {
    if ! command_exists "gcloud"; then
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        update_pkg_manager
        install_package "google-cloud-sdk"
        
        # Install additional components if development tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            gcloud components install beta cloud-run-proxy cloud-build-local --quiet
        fi
    fi
}

# Install Digital Ocean CLI
install_doctl() {
    if ! command_exists "doctl"; then
        VERSION=$(curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -LO https://github.com/digitalocean/doctl/releases/download/$VERSION/doctl-$VERSION-linux-amd64.tar.gz
        tar xf doctl-$VERSION-linux-amd64.tar.gz
        mv doctl /usr/local/bin
        rm doctl-$VERSION-linux-amd64.tar.gz
    fi
}

# Install common cloud development tools
install_cloud_tools() {
    if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
        # Install Serverless Framework
        if ! command_exists "serverless"; then
            npm install -g serverless
        fi
        
        # Install Pulumi
        if ! command_exists "pulumi"; then
            curl -fsSL https://get.pulumi.com | sh
            mv ~/.pulumi/bin/pulumi /usr/local/bin/
        fi
        
        # Install CloudFormation linter
        pip3 install cfn-lint
        
        # Install AWS Cloud Development Kit (CDK)
        npm install -g aws-cdk
    fi
}

# Main installation
DEFAULT_CLOUD=$(get_config_value "DEFAULT_CLOUD" "aws")
INSTALL_MULTIPLE=$(get_config_value "INSTALL_MULTIPLE_CLOUDS" "true")

# Install default cloud provider
case $DEFAULT_CLOUD in
    "aws")
        install_aws
        ;;
    "azure")
        install_azure
        ;;
    "gcloud")
        install_gcloud
        ;;
    *)
        log_error "Invalid default cloud provider: $DEFAULT_CLOUD"
        ;;
esac

# Install additional cloud providers if configured
if [ "$INSTALL_MULTIPLE" = "true" ]; then
    case $DEFAULT_CLOUD in
        "aws")
            install_azure
            install_gcloud
            ;;
        "azure")
            install_aws
            install_gcloud
            ;;
        "gcloud")
            install_aws
            install_azure
            ;;
    esac
fi

# Install DigitalOcean CLI if multiple clouds are enabled
if [ "$INSTALL_MULTIPLE" = "true" ]; then
    install_doctl
fi

# Install additional cloud development tools
install_cloud_tools

# Configure default cloud provider
case $DEFAULT_CLOUD in
    "aws")
        echo 'export AWS_PAGER=""' >> ~/.bashrc
        ;;
    "azure")
        az config set core.no_color=false
        az config set core.output=table
        ;;
    "gcloud")
        gcloud config set core/disable_usage_reporting true
        gcloud config set component_manager/disable_update_check true
        ;;
esac

log_info "Cloud Development Tools installation completed!"