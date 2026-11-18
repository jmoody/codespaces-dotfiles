# Shared frontmatter, code-fence, and indented-code handling for both formatting passes.
function verbatim_line(line,   text,marker,count,rest,stripped,indent){
  if(NR==1 && line ~ /^---[ \t]*$/){ frontmatter=1; return 1 }
  if(frontmatter){
    if(line ~ /^(---|\.\.\.)[ \t]*$/) frontmatter=0
    return 1
  }
  text=line
  sub(/\r$/,"",text)
  stripped=text
  sub(/^ */,"",stripped)
  indent=length(text)-length(stripped)
  if(fence_width){
    if(indent<=3 && match(stripped,/^(```+|~~~+)/)){
      marker=substr(stripped,1,1); count=RLENGTH; rest=substr(stripped,count+1)
      if(marker==fence_marker && count>=fence_width && rest ~ /^[ \t]*$/) fence_width=0
    }
    return 1
  }
  if(indent>=4 || line ~ /^[ ]*\t/) return 1
  if(indent<=3 && match(stripped,/^(```+|~~~+)/)){
    marker=substr(stripped,1,1); count=RLENGTH; rest=substr(stripped,count+1)
    if(marker=="`" && index(rest,"`")) return 0
    fence_marker=marker; fence_width=count
    return 1
  }
  return 0
}
