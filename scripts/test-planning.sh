#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -swift-version 5 Tests/PlanningTests.swift ReadyKit/Models/HouseholdProfile.swift ReadyKit/Services/ReadinessCalculator.swift ReadyKit/Services/PreparednessAdvice.swift -o "$build_dir/planning-tests"
"$build_dir/planning-tests"

