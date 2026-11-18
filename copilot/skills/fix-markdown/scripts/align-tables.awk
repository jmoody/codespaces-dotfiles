# Reformats GitHub-Flavored Markdown tables so pipes align vertically.
# - Column width = widest cell in that column (min 3).
# - Separator row keeps its alignment markers (:--- left, ---: right, :---: center).
# - Cells are padded per the column alignment (right-justify numbers, etc).
# Only contiguous blocks of lines starting with '|' whose 2nd line is a separator row
# are treated as tables; everything else passes through unchanged.
# Runs under any POSIX awk in the C locale: dlen() counts UTF-8 characters by
# discounting continuation bytes, so multibyte glyphs stay aligned without gawk.
function trim(s){ sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s); return s }
function is_sep_cell(c){ return (c ~ /^:?-+:?$/) }
function dlen(s,   t,n){ t=s; n=gsub(/[\200-\277]/,"",t); return length(s)-n }
function repeat(ch,n,   i,s){ s=""; for(i=0;i<n;i++) s=s ch; return s }
function pad(s,w,align,   n,l,r){
  n=w-dlen(s); if(n<0)n=0
  if(align=="right")  return repeat(" ",n) s
  if(align=="center"){ l=int(n/2); r=n-l; return repeat(" ",l) s repeat(" ",r) }
  return s repeat(" ",n)
}
function make_sep(w,align){
  if(w<3)w=3
  if(align=="center") return ":" repeat("-",w-2) ":"
  if(align=="right")  return repeat("-",w-1) ":"
  if(align=="left")   return ":" repeat("-",w-1)
  return repeat("-",w)
}
function split_cells(line,arr,   s,n,i,ch,slashes,ncols,last_separator){
  s=trim(line)
  sub(/^\|/,"",s)
  n=length(s); ncols=1; arr[ncols]=""; slashes=0; last_separator=0
  for(i=1;i<=n;i++){
    ch=substr(s,i,1)
    if(ch=="|" && slashes%2==0){
      ncols++; arr[ncols]=""; last_separator=1
    } else {
      arr[ncols]=arr[ncols] ch; last_separator=0
    }
    if(ch=="\\") slashes++; else slashes=0
  }
  if(last_separator) ncols--
  for(i=1;i<=ncols;i++) arr[i]=trim(arr[i])
  return ncols
}
function flush(   i,j,ncols,out,c,left,right){
  if(nrows==0) return
  ncols=cols[1]
  for(j=1;j<=ncols;j++){ width[j]=0; alignc[j]="none" }
  for(j=1;j<=cols[2];j++){
    c=cell[2,j]
    left=(substr(c,1,1)==":"); right=(substr(c,length(c),1)==":")
    if(left&&right) alignc[j]="center"; else if(right) alignc[j]="right"; else if(left) alignc[j]="left"; else alignc[j]="none"
  }
  for(i=1;i<=nrows;i++){ if(i==2) continue; for(j=1;j<=cols[i];j++){ if(dlen(cell[i,j])>width[j]) width[j]=dlen(cell[i,j]) } }
  for(j=1;j<=ncols;j++){ if(width[j]<3) width[j]=3 }
  for(i=1;i<=nrows;i++){
    out="|"
    for(j=1;j<=ncols;j++){
      if(i==2) out=out " " make_sep(width[j],alignc[j]) " |"
      else { c=(j<=cols[i])?cell[i,j]:""; out=out " " pad(c,width[j],alignc[j]) " |" }
    }
    print out
  }
  nrows=0
}
function process_block(   bi,cc,valid,k,n2,tmp,tmpc,mismatch){
  if(bn==0) return
  valid=0
  if(bn>=2){
    n2=split_cells(buf[2],tmp); valid=1
    for(k=1;k<=n2;k++) if(!is_sep_cell(tmp[k])){ valid=0; break }
    if(n2==0) valid=0
  }
  if(valid){
    nrows=bn
    for(bi=1;bi<=bn;bi++){ cols[bi]=split_cells(buf[bi],tmpc); for(cc=1;cc<=cols[bi];cc++) cell[bi,cc]=tmpc[cc] }
    mismatch=0
    for(bi=2;bi<=nrows;bi++){
      if(cols[bi]!=cols[1]){ mismatch=bi; break }
    }
    if(mismatch){
      for(bi=1;bi<=nrows;bi++) print buf[bi]
      printf "[ERROR] %s:%d: table row has %d columns; expected %d; left unchanged\n", ENVIRON["SOURCE_FILE"], block_line[mismatch], cols[mismatch], cols[1] > "/dev/stderr"
      invalid=1
    } else {
      flush()
    }
  } else { for(bi=1;bi<=bn;bi++) print buf[bi] }
  bn=0
}
{
  if(verbatim_line($0)){ process_block(); print $0; next }
  if($0 ~ /^\|/){ buf[++bn]=$0; block_line[bn]=FNR; next }
  process_block()
  print $0
}
END{ process_block(); if(invalid) exit 1 }
