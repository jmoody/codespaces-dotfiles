---
applyTo: "**/Dockerfile,**/docker-compose*.yml"
---
# Dockerfile instructions

This file is the single source of truth for all Dockerfile standards in this project.

## HEREDOC for multiline commands

**Always use HEREDOC syntax for multiline RUN commands.** Do not use backslash line continuations with `&&` chains.

### Correct (HEREDOC)

```dockerfile
RUN <<EOF
apt-get update
apt-get install -y package1 package2
rm -rf /var/lib/apt/lists/*
EOF
```

### Incorrect (backslash continuations)

```dockerfile
# Do NOT use this style
RUN apt-get update \
    && apt-get install -y package1 package2 \
    && rm -rf /var/lib/apt/lists/*
```

## Shell selection

Use `bash` when you need bash-specific features:

```dockerfile
RUN <<EOF bash
set -euo pipefail
if [[ -f /app/tmp/config ]]; then
  source /app/tmp/config
fi
EOF
```

## Single commands

Single commands do not require HEREDOC:

```dockerfile
COPY .terraform-version /app/tmp/.terraform-version
WORKDIR /app
ENV PATH="/usr/local/bin:$PATH"
```
