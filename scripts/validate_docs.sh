#!/bin/bash

# Documentation Validation Script
# Validates that all documentation files exist and have required sections

set -e

echo "🔍 Validating Odin RE2 Documentation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
    esac
}

# Check if file exists
check_file_exists() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        print_status "OK" "$description exists: $file"
        return 0
    else
        print_status "ERROR" "$description missing: $file"
        return 1
    fi
}

# Check if file contains required sections
check_file_sections() {
    local file=$1
    local sections=("${@:2}")
    local missing_sections=()
    
    for section in "${sections[@]}"; do
        if ! grep -q "$section" "$file"; then
            missing_sections+=("$section")
        fi
    done
    
    if [ ${#missing_sections[@]} -eq 0 ]; then
        print_status "OK" "All required sections found in $file"
        return 0
    else
        print_status "WARN" "Missing sections in $file: ${missing_sections[*]}"
        return 1
    fi
}

# Validate core documentation files
echo ""
echo "📚 Checking Core Documentation Files..."

error_count=0

# Root level documentation
check_file_exists "README.md" "Project README" || ((error_count++))
check_file_exists "PROJECT_STANDARDS.md" "Project Standards" || ((error_count++))
check_file_exists "CONTRIBUTING.md" "Contributing Guide" || ((error_count++))
check_file_exists "CHANGELOG.md" "Changelog" || ((error_count++))
check_file_exists "SECURITY.md" "Security Policy" || ((error_count++))
check_file_exists "LICENSE" "License" || ((error_count++))
check_file_exists "AGENTS.md" "AI Agents Guide" || ((error_count++))

# Documentation directory
check_file_exists "docs/README.md" "Documentation Index" || ((error_count++))
check_file_exists "docs/API.md" "API Documentation" || ((error_count++))
check_file_exists "docs/PERFORMANCE.md" "Performance Guide" || ((error_count++))
check_file_exists "docs/DEVELOPMENT.md" "Development Guide" || ((error_count++))
check_file_exists "docs/SyntaxReference.md" "Syntax Reference" || ((error_count++))
check_file_exists "docs/Examples.md" "Examples" || ((error_count++))

# Validate README.md sections
echo ""
echo "📖 Checking README.md sections..."
readme_sections=(
    "# Odin RE2 Implementation"
    "## ✨ Features"
    "## 🚀 Quick Start"
    "## 📊 Performance"
    "## 📁 Project Structure"
    "## 🧪 Testing"
)
check_file_sections "README.md" "${readme_sections[@]}" || ((error_count++))

# Validate PROJECT_STANDARDS.md sections
echo ""
echo "📋 Checking PROJECT_STANDARDS.md sections..."
standards_sections=(
    "# Odin RE2 项目规范文档"
    "## 项目架构"
    "## 编码规范"
    "## 构建和开发规范"
    "## 测试规范"
    "## 性能规范"
)
check_file_sections "PROJECT_STANDARDS.md" "${standards_sections[@]}" || ((error_count++))

# Validate CONTRIBUTING.md sections
echo ""
echo "🤝 Checking CONTRIBUTING.md sections..."
contributing_sections=(
    "# Contributing to Odin RE2"
    "## 开发环境设置"
    "## 贡献流程"
    "## 代码审查"
)
check_file_sections "CONTRIBUTING.md" "${contributing_sections[@]}" || ((error_count++))

# Validate API.md sections
echo ""
echo "🔧 Checking API.md sections..."
api_sections=(
    "# Odin RE2 API Documentation"
    "## Overview"
    "## Core API"
    "## Unicode Support"
    "## Error Handling"
)
check_file_sections "docs/API.md" "${api_sections[@]}" || ((error_count++))

# Validate PERFORMANCE.md sections
echo ""
echo "⚡ Checking PERFORMANCE.md sections..."
performance_sections=(
    "# Odin RE2 Performance Guide"
    "## Performance Overview"
    "## Key Performance Metrics"
    "## Core Optimizations"
)
check_file_sections "docs/PERFORMANCE.md" "${performance_sections[@]}" || ((error_count++))

# Check for broken links in markdown files
echo ""
echo "🔗 Checking for broken markdown links..."

# Function to check markdown links
check_markdown_links() {
    local file=$1
    local broken_links=()
    
    # Extract markdown links
    while IFS= read -r line; do
        # Match markdown links [text](url)
        if [[ $line =~ \[.*\]\(([^)]+)\) ]]; then
            link="${BASH_REMATCH[1]}"
            # Skip external links and anchors
            if [[ $link != http* ]] && [[ $link != "#"* ]]; then
                # Remove fragment if present
                link_path="${link%%#*}"
                if [ ! -f "$link_path" ] && [ ! -d "$link_path" ]; then
                    broken_links+=("$link")
                fi
            fi
        fi
    done < "$file"
    
    if [ ${#broken_links[@]} -eq 0 ]; then
        print_status "OK" "No broken links in $file"
        return 0
    else
        print_status "WARN" "Broken links in $file: ${broken_links[*]}"
        return 1
    fi
}

# Check links in main documentation files
for file in README.md PROJECT_STANDARDS.md CONTRIBUTING.md docs/README.md; do
    if [ -f "$file" ]; then
        check_markdown_links "$file" || ((error_count++))
    fi
done

# Check for consistent version numbers
echo ""
echo "🏷️  Checking version consistency..."

# Extract version from CHANGELOG.md
if [ -f "CHANGELOG.md" ]; then
    latest_version=$(grep -m1 "^## \[.*\]" CHANGELOG.md | sed 's/## \[\(.*\)\].*/\1/')
    if [ -n "$latest_version" ]; then
        print_status "OK" "Latest version in CHANGELOG.md: $latest_version"
        
        # Check if version is mentioned in README.md
        if grep -q "$latest_version" README.md; then
            print_status "OK" "Version $latest_version found in README.md"
        else
            print_status "WARN" "Version $latest_version not found in README.md"
            ((error_count++))
        fi
    else
        print_status "WARN" "Could not extract version from CHANGELOG.md"
        ((error_count++))
    fi
fi

# Summary
echo ""
echo "📊 Documentation Validation Summary"
echo "=================================="

if [ $error_count -eq 0 ]; then
    print_status "OK" "All documentation validation checks passed!"
    echo ""
    echo "🎉 Documentation is ready for release!"
    exit 0
else
    print_status "ERROR" "$error_count validation check(s) failed"
    echo ""
    echo "Please fix the above issues before releasing."
    exit 1
fi