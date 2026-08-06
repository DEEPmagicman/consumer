#!/usr/bin/env bash

set -uo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "${script_directory}/.." && pwd)"

simulator_udid="${SIMULATOR_UDID:-}"
if [[ -z "${simulator_udid}" ]]; then
    simulator_udid="$(
        xcrun simctl list devices booted \
            | sed -nE 's/.*\(([0-9A-Fa-f-]{36})\) \(Booted\).*/\1/p' \
            | head -n 1
    )"
fi

if [[ -z "${simulator_udid}" ]]; then
    echo "No booted iOS Simulator found. Boot a Simulator and run this script again." >&2
    exit 1
fi

timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
artifact_root="${TEST_ARTIFACTS_DIR:-${repository_root}/TestArtifacts/CoverPurchase}"
run_directory="${artifact_root}/${timestamp}"
video_path="${run_directory}/cover-purchase.mp4"
result_bundle_path="${run_directory}/CoverPurchase.xcresult"
test_log_path="${run_directory}/xcodebuild.log"

mkdir -p "${run_directory}"

echo "Recording Simulator ${simulator_udid}"
echo "Video: ${video_path}"
echo "Test result: ${result_bundle_path}"

xcrun simctl io "${simulator_udid}" recordVideo --codec=h264 "${video_path}" &
recording_pid=$!
recording_stopped=false

stop_recording() {
    if [[ "${recording_stopped}" == false ]]; then
        recording_stopped=true
        if kill -0 "${recording_pid}" 2>/dev/null; then
            kill -INT "${recording_pid}" 2>/dev/null || true
            wait "${recording_pid}" 2>/dev/null || true
        fi
    fi
}

trap stop_recording EXIT INT TERM

set +e
xcodebuild test \
    -workspace "${repository_root}/SpeakEasy-Consumer.xcworkspace" \
    -scheme SpeakEasyConsumerUITests \
    -testPlan SpeakEasyConsumerUITests \
    -destination "platform=iOS Simulator,id=${simulator_udid}" \
    -only-testing:SpeakEasyConsumerUITests/CoverTicketPurchaseUITests/testPurchaseLiveCoverWithNewCardShowsQRCode \
    -resultBundlePath "${result_bundle_path}" \
    | tee "${test_log_path}"
test_status=${PIPESTATUS[0]}
set -e

stop_recording
trap - EXIT INT TERM

echo "Saved recording to ${video_path}"
echo "Saved test result to ${result_bundle_path}"

exit "${test_status}"
