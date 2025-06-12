#!/bin/bash
set -euo pipefail

# === USAGE ===
# ./run-jmeter.sh [gui|cli] test-plan.jmx [env-name]
# Example:
# ./run-jmeter.sh gui test.jmx local
# ./run-jmeter.sh cli test.jmx dev

if [ -z "${JM_HOME:-}" ]; then
  BASE_DIR="$(pwd)"
else
  BASE_DIR="$JM_HOME"
fi

MODE="${1:-cli}"
JMX_FILE="${2:-}"
ENV_NAME="${3:-local}"

if [[ -z "$JMX_FILE" ]]; then
  echo "Error: Missing test plan (.jmx) file"
  echo "Usage: $0 [gui|cli] test-plan.jmx [env]"
  exit 1
fi

if [[ ! -f "$JMX_FILE" ]]; then
  echo "Error: File '$JMX_FILE' not found."
  exit 1
fi

ENV_FILE=".env.${ENV_NAME}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: Environment file '$ENV_FILE' not found."
  exit 1
fi

export $(grep -v '^#' "$ENV_FILE" | xargs)

echo "Running in mode: $MODE"
echo "Test Plan: $JMX_FILE"
echo "Environment: $ENV_FILE"
echo ""

if [[ "$MODE" == "gui" ]]; then
  echo "Launching JMeter GUI..."
  jmeter -t "$JMX_FILE" -JbaseDir="$BASE_DIR" -j /dev/stdout
else
  echo "Running JMeter in CLI mode..."
  jmeter -n -t "$JMX_FILE" -l results.jtl -JbaseDir="$BASE_DIR" -j /dev/stdout
  echo "Done. Results saved to results.jtl"
fi
