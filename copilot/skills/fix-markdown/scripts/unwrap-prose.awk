# Joins hard-wrapped Markdown prose and list items back into single logical lines.
# A blank line, heading, thematic break, table row (|), blockquote (>), list marker,
# or code fence (``` or ~~~) ends the current logical line. Ordered markers end in . or ).
# Continuation lines are trimmed and appended with a single space. Leading YAML frontmatter
# (a --- delimited block at the very top of the file), fenced code blocks, and tables pass through untouched.
function trim(s){ sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s); return s }
function has_hard_break(line,   slashes){
  if(line ~ /  +$/) return 1
  if(match(line,/\\+$/)){
    slashes=substr(line,RSTART,RLENGTH)
    return length(slashes)%2
  }
  return 0
}
function is_setext_underline(line,   text,indent){
  text=line
  sub(/^ */,"",text)
  indent=length(line)-length(text)
  return indent<=3 && (text ~ /^=+[ \t]*$/ || text ~ /^-+[ \t]*$/)
}
function is_thematic_break(line,   text,indent,marker){
  if(line ~ /^\t/) return 0
  text=line
  sub(/^ */,"",text)
  indent=length(line)-length(text)
  if(indent>3) return 0
  gsub(/[ \t]/,"",text)
  if(length(text)<3) return 0
  marker=substr(text,1,1)
  if(marker=="-") return text !~ /[^-]/
  if(marker=="*") return text !~ /[^*]/
  if(marker=="_") return text !~ /[^_]/
  return 0
}
function flush(   i,out){
  if(!inunit) return
  out=first
  for(i=1;i<=nc;i++) out=out " " cont[i]
  print out
  inunit=0; nc=0
}
{
  line=$0
  if(verbatim_line(line)){ flush(); print line; next }
  if(line ~ /^[ \t]*$/){ flush(); print line; next }
  if(line ~ /^#/ || line ~ /^\|/ || line ~ /^>/){ flush(); print line; next }
  if(is_setext_underline(line)){ flush(); print line; next }
  if(is_thematic_break(line)){ flush(); print line; next }
  if(line ~ /^[ \t]*[-*+] / || line ~ /^[ \t]*[0-9]+[.)] /){
    flush(); first=line; inunit=1; nc=0
    if(has_hard_break(line)) flush()
    next
  }
  if(inunit){ cont[++nc]=(has_hard_break(line) ? line : trim(line)) }
  else { first=line; inunit=1; nc=0 }
  if(has_hard_break(line)) flush()
}
END{ flush() }
