#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
# Run from a Git checkout so scratch files stay in its workspace.
REPO_ROOT="$(git rev-parse --show-toplevel)"
WORK_DIR="${REPO_ROOT}/tmp/fix-markdown-test-$$"
FORMATTER="${SCRIPT_DIR}/fix-markdown.sh"
two_backslashes="\\\\"

mkdir -p "${WORK_DIR}"
trap 'rm -rf "${WORK_DIR}"' EXIT

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

escaped_pipe="${WORK_DIR}/escaped-pipe.md"
cat > "${escaped_pipe}" <<'EOF'
| Code | Description |
| ---- | ----------- |
| `a \| b` | pipe in code |
| x \\| y |
EOF

"${FORMATTER}" "${escaped_pipe}"
grep -Fq 'a \| b' "${escaped_pipe}" || fail "escaped pipe was changed"
grep -Fq 'pipe in code' "${escaped_pipe}" || fail "cell after escaped pipe was dropped"
grep -Fq "x ${two_backslashes}" "${escaped_pipe}" || fail "even backslashes before a delimiter were changed"
"${FORMATTER}" --check "${escaped_pipe}"

mismatched_columns="${WORK_DIR}/mismatched-columns.md"
cat > "${mismatched_columns}" <<'EOF'
| A | B |
| - | - |
| 1 | 2 | 3 |
EOF
cp "${mismatched_columns}" "${WORK_DIR}/mismatched-columns.original"

if "${FORMATTER}" "${mismatched_columns}" 2>"${WORK_DIR}/error"; then
  fail "a table with mismatched column counts was accepted"
fi
cmp -s "${mismatched_columns}" "${WORK_DIR}/mismatched-columns.original" \
  || fail "a malformed table was modified"
grep -Fq "column" "${WORK_DIR}/error" || fail "column mismatch was not reported"

symlink_target="${WORK_DIR}/symlink-target.md"
symlink_input="${WORK_DIR}/symlink-input.md"
printf 'wrapped\nprose\n' > "${symlink_target}"
cp "${symlink_target}" "${WORK_DIR}/symlink-target.expected"
ln -s "${symlink_target}" "${symlink_input}"
if "${FORMATTER}" "${symlink_input}" 2>"${WORK_DIR}/symlink-error"; then
  fail "a symlink input was accepted"
fi
[[ -L "${symlink_input}" ]] || fail "the symlink was replaced"
cmp -s "${symlink_target}" "${WORK_DIR}/symlink-target.expected" \
  || fail "the symlink target was modified"
grep -Fq "symbolic link" "${WORK_DIR}/symlink-error" || fail "symlink rejection was not reported"

if "${FORMATTER}" --check "${mismatched_columns}" 2>"${WORK_DIR}/check-error"; then
  fail "--check accepted a table with mismatched column counts"
fi

tilde_fence="${WORK_DIR}/tilde-fence.md"
cat > "${tilde_fence}" <<'EOF'
~~~text
first line
second line
~~~
EOF
cp "${tilde_fence}" "${WORK_DIR}/tilde-fence.expected"
"${FORMATTER}" "${tilde_fence}"
diff -u "${WORK_DIR}/tilde-fence.expected" "${tilde_fence}" \
  || fail "tilde-fenced code was modified"
"${FORMATTER}" --check "${tilde_fence}"

hard_breaks="${WORK_DIR}/hard-breaks.md"
printf 'two-space break  \ncontinued line\n\nbackslash break\\\ncontinued line\n' > "${hard_breaks}"
cp "${hard_breaks}" "${WORK_DIR}/hard-breaks.expected"
"${FORMATTER}" --check "${hard_breaks}"
"${FORMATTER}" "${hard_breaks}"
cmp -s "${WORK_DIR}/hard-breaks.expected" "${hard_breaks}" \
  || fail "a Markdown hard break was changed"

hard_break_after_wrap="${WORK_DIR}/hard-break-after-wrap.md"
printf 'before\ncontinued with spaces  \nafter\n\nbefore\ncontinued with slash\\\nafter\n' > "${hard_break_after_wrap}"
cat > "${WORK_DIR}/hard-break-after-wrap.expected" <<'EOF'
before continued with spaces  
after

before continued with slash\
after
EOF
"${FORMATTER}" "${hard_break_after_wrap}"
diff -u "${WORK_DIR}/hard-break-after-wrap.expected" "${hard_break_after_wrap}" \
  || fail "a hard break after a soft-wrapped line was changed"

setext_headings="${WORK_DIR}/setext-headings.md"
cat > "${setext_headings}" <<'EOF'
Equals heading
==============

Hyphen heading
--------------
EOF
cp "${setext_headings}" "${WORK_DIR}/setext-headings.expected"
"${FORMATTER}" "${setext_headings}"
diff -u "${WORK_DIR}/setext-headings.expected" "${setext_headings}" \
  || fail "setext heading underlines were changed"

thematic_breaks="${WORK_DIR}/thematic-breaks.md"
cat > "${thematic_breaks}" <<'EOF'
Asterisk rule
***
Following
paragraph

Spaced asterisk rule
* * *
Following
paragraph

Underscore rule
___
Following
paragraph

Spaced underscore rule
_ _ _
Following
paragraph

Spaced hyphen rule
- - -
Following
paragraph
EOF
cat > "${WORK_DIR}/thematic-breaks.expected" <<'EOF'
Asterisk rule
***
Following paragraph

Spaced asterisk rule
* * *
Following paragraph

Underscore rule
___
Following paragraph

Spaced underscore rule
_ _ _
Following paragraph

Spaced hyphen rule
- - -
Following paragraph
EOF
"${FORMATTER}" "${thematic_breaks}"
diff -u "${WORK_DIR}/thematic-breaks.expected" "${thematic_breaks}" \
  || fail "a thematic break was joined to prose or treated as a list"

paren_ordered_list="${WORK_DIR}/paren-ordered-list.md"
cat > "${paren_ordered_list}" <<'EOF'
1) First item
continued
2) Second item
continued
EOF
cat > "${WORK_DIR}/paren-ordered-list.expected" <<'EOF'
1) First item continued
2) Second item continued
EOF
"${FORMATTER}" "${paren_ordered_list}"
diff -u "${WORK_DIR}/paren-ordered-list.expected" "${paren_ordered_list}" \
  || fail "parenthesis-style ordered-list items were joined"

indented_code="${WORK_DIR}/indented-code.md"
cat > "${indented_code}" <<'EOF'
Paragraph before

    first code line
    second code line
    | A | B |
    |---|---|
    | a | b |
    ``` literal fence text

Following
paragraph

- Example:

      nested first
      nested second

Following
paragraph
EOF
cat > "${WORK_DIR}/indented-code.expected" <<'EOF'
Paragraph before

    first code line
    second code line
    | A | B |
    |---|---|
    | a | b |
    ``` literal fence text

Following paragraph

- Example:

      nested first
      nested second

Following paragraph
EOF
"${FORMATTER}" "${indented_code}"
diff -u "${WORK_DIR}/indented-code.expected" "${indented_code}" \
  || fail "indented code or prose after it was changed"

crlf_fence="${WORK_DIR}/crlf-fence.md"
printf '~~~text\r\nfirst line\r\nsecond line\r\n~~~ \t\r\n\nWrapped\nafter.\n' > "${crlf_fence}"
printf '~~~text\r\nfirst line\r\nsecond line\r\n~~~ \t\r\n\nWrapped after.\n' > "${WORK_DIR}/crlf-fence.expected"
"${FORMATTER}" "${crlf_fence}"
diff -u "${WORK_DIR}/crlf-fence.expected" "${crlf_fence}" \
  || fail "a CRLF fence or closing-fence whitespace was mishandled"

cat > "${WORK_DIR}/fences.literal" <<'EOF'
````markdown
first line
second line
```
~~~
| A | B |
|---|---|
| 1 | 2 | 3 |
````

   ~~~~text
first line
second line
   ~~~
   ```
   ~~~~not a closing fence
| A | B |
|---|---|
| 1 | 2 |
   ~~~~~
EOF

fence_boundaries="${WORK_DIR}/fence-boundaries.md"
{
  printf '%s\n' '---' 'example: |' '  ~~~' '---' ''
  printf 'Wrapped\nbefore.\n\n'
  cat "${WORK_DIR}/fences.literal"
  printf '\nWrapped\nafter.\n\n'
  printf '%s\n' '| A | B |' '|---|---|' '| 1 | 2 |'
} > "${fence_boundaries}"
{
  printf '%s\n' '---' 'example: |' '  ~~~' '---' ''
  printf 'Wrapped before.\n\n'
  cat "${WORK_DIR}/fences.literal"
  printf '\nWrapped after.\n\n'
  printf '%s\n' '| A   | B   |' '| --- | --- |' '| 1   | 2   |'
} > "${WORK_DIR}/fence-boundaries.expected"
"${FORMATTER}" "${fence_boundaries}"
diff -u "${WORK_DIR}/fence-boundaries.expected" "${fence_boundaries}" \
  || fail "fence boundaries or formatting outside fences changed"
"${FORMATTER}" --check "${fence_boundaries}"

unclosed_fence="${WORK_DIR}/unclosed-fence.md"
cat > "${unclosed_fence}" <<'EOF'
~~~text
first line
second line

| A | B |
|---|---|
| 1 | 2 | 3 |
EOF
cp "${unclosed_fence}" "${WORK_DIR}/unclosed-fence.expected"
"${FORMATTER}" --check "${unclosed_fence}"
"${FORMATTER}" "${unclosed_fence}"
cmp -s "${WORK_DIR}/unclosed-fence.expected" "${unclosed_fence}" \
  || fail "an unclosed fence did not protect content through EOF"

inline_code="${WORK_DIR}/inline-code.md"
cat > "${inline_code}" <<'EOF'
```inline code```
continued prose.
EOF
cat > "${WORK_DIR}/inline-code.expected" <<'EOF'
```inline code``` continued prose.
EOF
"${FORMATTER}" "${inline_code}"
diff -u "${WORK_DIR}/inline-code.expected" "${inline_code}" \
  || fail "inline backticks were treated as a code fence"

echo "[PASS] Markdown formatter regression tests"
