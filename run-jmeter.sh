#!/usr/bin/env bash
set -euo pipefail

DEFAULT_MODE="gui"
DEFAULT_JMX="scenarios/test.jmx"
DEFAULT_ENV="perf-test"

usage() {
  cat <<EOF
Usage: $0 [-m mode] [-f test-plan.jmx] [-e env]

  -m mode             JMeter mode: gui or cli (default: $DEFAULT_MODE)
  -f test-plan.jmx    .jmx file to run     (default: $DEFAULT_JMX)
  -e env              environment name     (default: $DEFAULT_ENV)
  -h                  show this help
EOF
  exit 1
}

# Defaults
MODE="$DEFAULT_MODE"
JMX_FILE="$DEFAULT_JMX"
ENV_NAME="$DEFAULT_ENV"

while getopts ":m:f:e:h" opt; do
  case $opt in
    m) MODE="$OPTARG" ;;
    f) JMX_FILE="$OPTARG" ;;
    e) ENV_NAME="$OPTARG" ;;
    h) usage ;;
    \?) echo "Error: invalid option -$OPTARG"; usage ;;
    :)  echo "Error: -$OPTARG requires an argument"; usage ;;
  esac
done
shift $((OPTIND -1))

if [[ "$JMX_FILE" == "$DEFAULT_JMX" && ! -f "$JMX_FILE" ]]; then
  matches=( *.jmx )
  if (( ${#matches[@]} == 1 )); then
    JMX_FILE="${matches[0]}"
  else
    echo "Default JMX '$DEFAULT_JMX' not found."
    exit 1
  fi
fi

if [[ "$MODE" != "cli" && "$MODE" != "gui" ]]; then
  echo "mode must be 'cli' or 'gui'." >&2
  exit 1
fi

if [[ ! -f "$JMX_FILE" ]]; then
  echo "JMX file '$JMX_FILE' not found." >&2
  exit 1
fi

ENV_FILE=".env.${ENV_NAME}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Environment file '$ENV_FILE' not found." >&2
  exit 1
fi

export $(grep -v '^#' "$ENV_FILE" | xargs)

echo "Mode:       $MODE"
echo "Test Plan:  $JMX_FILE"
echo "Environment: $ENV_NAME"
echo

if [[ "$MODE" == "gui" ]]; then
  jmeter -t "$JMX_FILE" -JbaseDir="$(pwd)" -j /dev/stdout
else
  jmeter -n -t "$JMX_FILE" -l results.jtl -JbaseDir="$(pwd)" -j /dev/stdout
fi
