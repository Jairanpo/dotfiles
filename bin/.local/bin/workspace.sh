#!/usr/bin/env bash

# Define the base directory for all projects
# VAGRANT: /home/vagrant/workspace/repos/project-name/here

get_work_directories(){
  PATHS=(
    "$HOME/ws/repos"
  )

  # OS: /home/jair/workspace/client-name/workspace/repos/project-name/here
  for deep_root in "$HOME/ws"/*/ws/repos; do
      if [ -d "$deep_root" ]; then
          PATHS+=("$deep_root")
      fi
  done

  SEARCH_PATTERNS=(
    "*/main"
    "*/master"
    "*/develop"
    "*/feature/*"
    "*/feat/*"
    "*/fix/*"
  )

  args=("(")
  first=true
  for pattern in "${SEARCH_PATTERNS[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      args+=("-o")
    fi
    args+=("-path")
    args+=("$pattern")
  done

  args+=( \) )

  echo $(find "${PATHS[@]}" -maxdepth 3 -type d "${args[@]}" 2> /dev/null | fzf)
}
