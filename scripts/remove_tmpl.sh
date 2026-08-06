#!/usr/bin/env bash
find "home/.chezmoitemplates" -type f -name '*.tmpl' -exec bash -c 'for f; do mv -- "$f" "${f%.tmpl}"; done' bash {} +