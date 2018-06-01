#!/bin/bash
if  [[ $1 = "--list" ]]; then
  cat ./inventory.json
fi
