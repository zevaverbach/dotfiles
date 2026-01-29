#!/bin/bash

cd $1 2>/dev/null
git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
if [ -n "$git_branch" ]; then
  echo "🔱$git_branch"
else
  echo ""
fi

