#!/usr/bin/env bash

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly KUBERNETES_DIR="${REPO_ROOT}/kubernetes"
readonly APPS_DIR="${KUBERNETES_DIR}/apps"
readonly REPOS_DIR="${KUBERNETES_DIR}/flux/meta/repos"


# Check if required tools are available
check_dependencies() {
    local deps=("gum" "yq")
    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &>/dev/null; then
            gum log --level error "Required dependency '${dep}' is not installed"
            exit 1
        fi
    done
}

# Get list of existing namespaces
get_existing_namespaces() {
    find "${APPS_DIR}" -maxdepth 1 -type d -not -path "${APPS_DIR}" -exec basename {} \; | sort
}

# Get list of available Helm repositories
get_available_helm_repos() {
    find "${REPOS_DIR}" -name "*.yaml" -not -name "kustomization.yaml" -exec basename {} .yaml \; | sort
}

# Generate HelmRepository YAML
generate_helmrepository() {
    local repo_name="$1"
    local repo_url="$2"
    
    cat << EOF
---
# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrepository-source-v1.json
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: ${repo_name}
  namespace: flux-system
spec:
  interval: 1h
  url: ${repo_url}
EOF
}

# Add new Helm repository to flux/meta/repos
add_helm_repository() {
    local repo_name="$1"
    local repo_url="$2"
    
    local repo_file="${REPOS_DIR}/${repo_name}.yaml"
    local kustomization_file="${REPOS_DIR}/kustomization.yaml"
    
    gum log --level info "Creating HelmRepository: ${repo_name}"
    generate_helmrepository "${repo_name}" "${repo_url}" > "${repo_file}"
    
    # Add to kustomization.yaml if not already present
    if ! grep -q "./\${repo_name}.yaml" "${kustomization_file}"; then
        gum log --level info "Adding ${repo_name} to repos kustomization"
        echo "  - ./${repo_name}.yaml" >> "${kustomization_file}"
    fi
}

# Validate app name
validate_app_name() {
    local app_name="$1"

    # Check if name is valid DNS label
    if [[ ! "${app_name}" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
        gum log --level error "App name must be a valid DNS label (lowercase letters, numbers, hyphens)"
        return 1
    fi

    # Check length
    if [[ ${#app_name} -gt 63 ]]; then
        gum log --level error "App name must be 63 characters or less"
        return 1
    fi

    return 0
}

# Check if app already exists
check_app_exists() {
    local namespace="$1"
    local app_name="$2"

    if [[ -d "${APPS_DIR}/${namespace}/${app_name}" ]]; then
        gum log --level error "App '${app_name}' already exists in namespace '${namespace}'"
        return 1
    fi

    return 0
}

# Collect user input
collect_input() {
    gum log --level info "Starting Kubernetes app scaffolding..."
    echo

    # App name
    while true; do
        APP_NAME=$(gum input --placeholder "Enter app name (e.g., my-app)")
        if [[ -n "${APP_NAME}" ]] && validate_app_name "${APP_NAME}"; then
            break
        fi
    done

    # Namespace selection
    local namespaces=($(get_existing_namespaces))
    namespaces+=("Create new namespace...")

    NAMESPACE=$(gum choose --header "Select namespace:" "${namespaces[@]}")

    if [[ "${NAMESPACE}" == "Create new namespace..." ]]; then
        while true; do
            NAMESPACE=$(gum input --placeholder "Enter new namespace name")
            if [[ -n "${NAMESPACE}" ]] && validate_app_name "${NAMESPACE}"; then
                gum log --level info "Will create new namespace: ${NAMESPACE}"
                break
            fi
        done
    fi

    # Check if app already exists
    if ! check_app_exists "${NAMESPACE}" "${APP_NAME}"; then
        exit 1
    fi

    # Chart type selection
    CHART_TYPE=$(gum choose --header "Select chart type:" "app-template" "standard-helm")
    
    if [[ "${CHART_TYPE}" == "app-template" ]]; then
        # Image repository
        IMAGE_REPO=$(gum input --placeholder "Enter image repository (e.g., nginx, ghcr.io/user/app)")
        
        # Image tag
        IMAGE_TAG=$(gum input --placeholder "Enter image tag" --value "latest")
    else
        # Standard Helm chart inputs
        local helm_repos=($(get_available_helm_repos))
        helm_repos+=("Create new Helm repository...")
        
        HELM_REPO=$(gum choose --header "Select Helm repository:" "${helm_repos[@]}")
        
        if [[ "${HELM_REPO}" == "Create new Helm repository..." ]]; then
            HELM_REPO=$(gum input --placeholder "Enter new repository name (e.g., my-charts)")
            HELM_REPO_URL=$(gum input --placeholder "Enter repository URL (e.g., https://charts.example.com)")
            
            # Validate repository name
            if [[ ! "${HELM_REPO}" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
                gum log --level error "Repository name must be a valid DNS label"
                exit 1
            fi
            
            # Check if repository already exists
            if [[ -f "${REPOS_DIR}/${HELM_REPO}.yaml" ]]; then
                gum log --level error "Repository '${HELM_REPO}' already exists"
                exit 1
            fi
            
            gum log --level info "Will create new HelmRepository: ${HELM_REPO}"
        fi
        
        CHART_NAME=$(gum input --placeholder "Enter chart name (e.g., authentik, external-dns)")
        
        CHART_VERSION=$(gum input --placeholder "Enter chart version (leave empty for latest)")
        if [[ -z "${CHART_VERSION}" ]]; then
            CHART_VERSION="latest"
        fi
    fi

    # ExternalSecret
    CREATE_EXTERNALSECRET=$(gum choose --header "Create ExternalSecret?" "Yes" "No")

    # Summary
    echo
    if [[ "${CHART_TYPE}" == "app-template" ]]; then
        gum style --foreground 212 --border-foreground 212 --border double \
            --align center --width 60 --margin "1 2" --padding "2 4" \
            "App Configuration Summary" \
            "" \
            "App Name: ${APP_NAME}" \
            "Namespace: ${NAMESPACE}" \
            "Chart Type: ${CHART_TYPE}" \
            "Image: ${IMAGE_REPO}:${IMAGE_TAG}" \
            "ExternalSecret: ${CREATE_EXTERNALSECRET}"
    else
        gum style --foreground 212 --border-foreground 212 --border double \
            --align center --width 60 --margin "1 2" --padding "2 4" \
            "App Configuration Summary" \
            "" \
            "App Name: ${APP_NAME}" \
            "Namespace: ${NAMESPACE}" \
            "Chart Type: ${CHART_TYPE}" \
            "Helm Repo: ${HELM_REPO}${HELM_REPO_URL:+ (${HELM_REPO_URL})}" \
            "Chart: ${CHART_NAME}" \
            "Version: ${CHART_VERSION}" \
            "ExternalSecret: ${CREATE_EXTERNALSECRET}"
    fi

    echo
    if ! gum confirm "Proceed with app creation?"; then
        gum log --level info "Cancelled by user"
        exit 0
    fi
}

# Generate ks.yaml (Flux Kustomization)
generate_ks_yaml() {
    local namespace="$1"
    local app_name="$2"

    cat <<EOF
---
# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/kustomization-kustomize-v1.json
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app ${app_name}
  namespace: &namespace ${namespace}
spec:
  commonMetadata:
    labels:
      app.kubernetes.io/name: *app
  decryption:
    provider: sops
    secretRef:
      name: sops-age
  interval: 1h
  path: ./kubernetes/apps/${namespace}/${app_name}/app
  postBuild:
    substituteFrom:
      - name: cluster-secrets
        kind: Secret
  prune: true
  retryInterval: 2m
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  targetNamespace: *namespace
  timeout: 5m
  wait: false
EOF
}

# Generate app kustomization.yaml
generate_app_kustomization() {
    local create_externalsecret="$1"

    local resources="  - ./helmrelease.yaml"
    if [[ "${create_externalsecret}" == "Yes" ]]; then
        resources="${resources}
  - ./externalsecret.yaml"
    fi

    cat <<EOF
---
# yaml-language-server: \$schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
${resources}
EOF
}

# Generate HelmRelease for app-template
generate_helmrelease() {
    local app_name="$1"
    local image_repo="$2"
    local image_tag="$3"

    cat <<EOF
---
# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrelease-helm-v2.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ${app_name}
spec:
  interval: 1h
  chartRef:
    kind: OCIRepository
    name: app-template
  install:
    remediation:
      retries: -1
  upgrade:
    cleanupOnFail: true
    remediation:
      retries: 3
  values:
    controllers:
      ${app_name}:
        strategy: RollingUpdate
        containers:
          app:
            image:
              repository: ${image_repo}
              tag: ${image_tag}
            resources:
              requests:
                cpu: 10m
              limits:
                memory: 128Mi
EOF
}

# Generate HelmRelease for standard Helm charts
generate_helmrelease_standard() {
    local app_name="$1"
    local helm_repo="$2"
    local chart_name="$3"
    local chart_version="$4"

    local version_spec=""
    if [[ "${chart_version}" != "latest" ]]; then
        version_spec="      version: ${chart_version}"
    fi

    cat <<EOF
---
# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrelease-helm-v2.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ${app_name}
spec:
  interval: 1h
  chart:
    spec:
      chart: ${chart_name}
${version_spec}
      sourceRef:
        kind: HelmRepository
        name: ${helm_repo}
        namespace: flux-system
  install:
    remediation:
      retries: 3
  upgrade:
    cleanupOnFail: true
    remediation:
      strategy: rollback
      retries: 3
  values:
    # Add your chart-specific configuration here
    resources:
      requests:
        cpu: 10m
      limits:
        memory: 128Mi
EOF
}

# Generate ExternalSecret
generate_externalsecret() {
    local app_name="$1"

    cat <<EOF
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: ${app_name}
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword
  target:
    name: ${app_name}-secret
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: ${app_name}
EOF
}

# Create directory structure and files
create_app_structure() {
    local namespace="$1"
    local app_name="$2"
    local chart_type="$3"
    local create_externalsecret="$4"
    # Additional parameters for different chart types
    local param1="${5:-}"
    local param2="${6:-}"
    local param3="${7:-}"
    local param4="${8:-}"

    local app_dir="${APPS_DIR}/${namespace}/${app_name}"
    local app_subdir="${app_dir}/app"

    gum log --level info "Creating directory structure..."
    mkdir -p "${app_subdir}"

    # Generate ks.yaml
    gum log --level info "Generating ks.yaml..."
    generate_ks_yaml "${namespace}" "${app_name}" >"${app_dir}/ks.yaml"

    # Generate app/kustomization.yaml
    gum log --level info "Generating app/kustomization.yaml..."
    generate_app_kustomization "${create_externalsecret}" >"${app_subdir}/kustomization.yaml"

    # Generate app/helmrelease.yaml
    gum log --level info "Generating app/helmrelease.yaml..."
    if [[ "${chart_type}" == "app-template" ]]; then
        generate_helmrelease "${app_name}" "${param1}" "${param2}" >"${app_subdir}/helmrelease.yaml"
    else
        generate_helmrelease_standard "${app_name}" "${param1}" "${param2}" "${param3}" >"${app_subdir}/helmrelease.yaml"
    fi

    # Generate app/externalsecret.yaml if requested
    if [[ "${create_externalsecret}" == "Yes" ]]; then
        gum log --level info "Generating app/externalsecret.yaml..."
        generate_externalsecret "${app_name}" >"${app_subdir}/externalsecret.yaml"
    fi
}

# Update namespace kustomization.yaml
update_namespace_kustomization() {
    local namespace="$1"
    local app_name="$2"

    local namespace_kustomization="${APPS_DIR}/${namespace}/kustomization.yaml"

    # Create namespace directory and kustomization if it doesn't exist
    if [[ ! -f "${namespace_kustomization}" ]]; then
        gum log --level info "Creating new namespace kustomization..."
        mkdir -p "${APPS_DIR}/${namespace}"
        cat <<EOF >"${namespace_kustomization}"
---
# yaml-language-server: \$schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${namespace}
components:
  - ../../components/common
resources:
  - ./${app_name}/ks.yaml
EOF
    else
        gum log --level info "Updating namespace kustomization..."
        # Add the new app to the resources list
        if ! grep -q "./${app_name}/ks.yaml" "${namespace_kustomization}"; then
            echo "  - ./${app_name}/ks.yaml" >>"${namespace_kustomization}"
        fi
    fi
}

# Validate generated YAML files
validate_yaml_files() {
    local namespace="$1"
    local app_name="$2"

    gum log --level info "Validating generated YAML files..."

    local app_dir="${APPS_DIR}/${namespace}/${app_name}"
    local files=("${app_dir}/ks.yaml" "${app_dir}/app/kustomization.yaml" "${app_dir}/app/helmrelease.yaml")

    if [[ "${CREATE_EXTERNALSECRET}" == "Yes" ]]; then
        files+=("${app_dir}/app/externalsecret.yaml")
    fi

    for file in "${files[@]}"; do
        if ! yq eval 'true' "${file}" &>/dev/null; then
            gum log --level error "Invalid YAML in file: ${file}"
            return 1
        fi
    done

    gum log --level info "All YAML files are valid"
    return 0
}

# Main function
main() {
    check_dependencies
    collect_input

    # Create new Helm repository if needed
    if [[ "${CHART_TYPE}" == "standard-helm" && -n "${HELM_REPO_URL:-}" ]]; then
        add_helm_repository "${HELM_REPO}" "${HELM_REPO_URL}"
    fi
    
    if [[ "${CHART_TYPE}" == "app-template" ]]; then
        create_app_structure "${NAMESPACE}" "${APP_NAME}" "${CHART_TYPE}" "${CREATE_EXTERNALSECRET}" "${IMAGE_REPO}" "${IMAGE_TAG}"
    else
        create_app_structure "${NAMESPACE}" "${APP_NAME}" "${CHART_TYPE}" "${CREATE_EXTERNALSECRET}" "${HELM_REPO}" "${CHART_NAME}" "${CHART_VERSION}"
    fi
    update_namespace_kustomization "${NAMESPACE}" "${APP_NAME}"

    if ! validate_yaml_files "${NAMESPACE}" "${APP_NAME}"; then
        gum log --level error "YAML validation failed"
        exit 1
    fi

    echo
    gum log --level info "Successfully scaffolded Kubernetes app '${APP_NAME}' in namespace '${NAMESPACE}'"
    gum log --level info "Generated files:"
    gum log --level info "  - kubernetes/apps/${NAMESPACE}/${APP_NAME}/ks.yaml"
    gum log --level info "  - kubernetes/apps/${NAMESPACE}/${APP_NAME}/app/kustomization.yaml"
    if [[ "${CHART_TYPE}" == "app-template" ]]; then
        gum log --level info "  - kubernetes/apps/${NAMESPACE}/${APP_NAME}/app/helmrelease.yaml (app-template: ${IMAGE_REPO}:${IMAGE_TAG})"
    else
        gum log --level info "  - kubernetes/apps/${NAMESPACE}/${APP_NAME}/app/helmrelease.yaml (${HELM_REPO}/${CHART_NAME}:${CHART_VERSION})"
        if [[ -n "${HELM_REPO_URL:-}" ]]; then
            gum log --level info "  - kubernetes/flux/meta/repos/${HELM_REPO}.yaml (new repository)"
        fi
    fi
    if [[ "${CREATE_EXTERNALSECRET}" == "Yes" ]]; then
        gum log --level info "  - kubernetes/apps/${NAMESPACE}/${APP_NAME}/app/externalsecret.yaml"
    fi

    echo
    gum log --level info "Next steps:"
    gum log --level info "1. Review and customize the generated files as needed"
    gum log --level info "2. Commit the changes to your repository"
    gum log --level info "3. Push to trigger Flux deployment"
}

# Run main function
main "$@"
