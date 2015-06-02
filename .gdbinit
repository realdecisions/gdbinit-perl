set $perl = 0
set $ctx = 0

define getperl
    if $ctx == 0
        set $ctx = Perl_get_context()  
    end
    set $perl = (PerlInterpreter*)$ctx 
end


define getperl_cored
    set $perl = (PerlInterpreter*)my_perl 
end


define perl_backtrace_cored
    getperl_cored
    set $curcop = (COP*)$perl->Icurcop
    set $cursub = (SV*)$perl->Isubname
    printf "======================\n"
    printf "file: %s , line: %d , subname: %s\n" , $curcop->cop_file, (int)$curcop->cop_line, $cursub->sv_u->svu_pv
    set $max_stack =  $perl->Icurstackinfo->si_cxix
    set $cx_stack   =  $perl->Icurstackinfo->si_cxstack
    while (int)$max_stack >= 0
      set $curcop = ($cx_stack+$max_stack)->cx_u->cx_blk->blku_oldcop
      set $curcv  = ($cx_stack+$max_stack)->cx_u->cx_blk->blk_u->blku_sub->cv
      set $file   = $curcop->cop_file
      set $line   = $curcop->cop_line
      printf "======================\n"
      printf "file: %s , line %d \n", $file, (int)$line
      set $max_stack = $max_stack-1
    end
end

define perl_trace_cored
    getperl_cored
    set $curcop = (COP*)$perl->Icurcop
    set $cursub = (SV*)$perl->Isubname
    printf "======================\n"
    printf "file: %s , line: %d , subname: %s\n" , $curcop->cop_file, (int)$curcop->cop_line, $cursub->sv_u->svu_pv
    set $max_stack  = 0
    set $cx_stack   =  $perl->Icurstackinfo->si_cxstack
    while (int)$max_stack >= 0
      set $curcop = ($cx_stack+$max_stack)->cx_u->cx_blk->blku_oldcop
      set $curcv  = ($cx_stack+$max_stack)->cx_u->cx_blk->blk_u->blku_sub->cv
      set $file   = $curcop->cop_file
      set $line   = $curcop->cop_line
      printf "======================\n"
      printf "file: %s , line %d, ", $file, (int)$line
      if $curcv != 0
        print_argv ($cx_stack+$max_stack)->cx_u->cx_blk->blk_u->blku_sub->argarray
      end
      printf "\n"
      set $max_stack = $max_stack+1
    end
end
set $undef = "undef"

define print_argv
  set $argarray = (AV*)$arg0
  set $maxidx   = $argarray->sv_any->xav_max
  set $curidx   = 0
  printf "Args count: %d; ",$maxidx+1
  printf "( "
  while (int)$curidx <= (int)$maxidx
    set $argsv = (SV**)(($argarray->sv_u->svu_array)+$curidx)

    if $argsv->sv_u->svu_pv != 0
      printf "%s",$argsv->sv_u->svu_pv
    else
      printf "undef"
    end

    set $curidx = $curidx + 1
    if $curidx <= $maxidx
      printf ", "
    end
  end
  printf " )\n"
  set $maxidx = 0
  set $curidx   = 0
end


define longmess
    getperl
    set $sv = Perl_eval_pv((void*)$perl,"require Carp; Carp::longmess()",0)
    printpv $sv
end
