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
      if $curcv != 0
        print_argv ($cx_stack+$max_stack)->cx_u->cx_blk->blk_u->blku_sub->argarray
      end
      set $max_stack = $max_stack-1
    end
end

define perl_trace_cored
    getperl_cored
    set $max_stack  = 0
    set $cx_stack   =  $perl->Icurstackinfo->si_cxstack

    set $curcop = (COP*)$perl->Icurcop
    set $cursub = (SV*)$perl->Isubname
    printf "======================\n"
    printf "file: %s , line: %d , subname: %s\n" , $curcop->cop_file, (int)$curcop->cop_line, $cursub->sv_u->svu_pv

    while (int)$max_stack >= 0
      set $cur_cx = ($cx_stack+$max_stack)
      set $curcop = $cur_cx->cx_u->cx_blk->blku_oldcop
        set $curcv  = $cur_cx->cx_u->cx_blk->blk_u->blku_sub->cv
        set $file   = $curcop->cop_file
        set $line   = $curcop->cop_line
        printf "======================\n"
        printf "file: %s , line %d, ", $file, (int)$line
        if $curcv
          if $cur_cx->cx_u
            if $cur_cx->cx_u->cx_blk
              if $cur_cx->cx_u->cx_blk->blk_u
                if $cur_cx->cx_u->cx_blk->blk_u->blku_sub
                  print_argv ($cx_stack+$max_stack)->cx_u->cx_blk->blk_u->blku_sub->argarray
                end
              end
            end
          end
        end
        printf "\n"
      set $max_stack = $max_stack+1
    end
end
set $undef = "undef"

define print_argv
  set $argarray = (AV*)$arg0
  if $argarray != 0 && $argarray->sv_any != 0
    set $maxidx   = $argarray->sv_any->xav_max
    set $curidx   = 0
    printf "Args count: %d; ",$maxidx+1
    printf "( "
    while (int)$curidx <= (int)$maxidx
      set $argsv = (SV**)(($argarray->sv_u->svu_array)+$curidx)

      if $argsv
        printsv $argsv
      end

      set $curidx = $curidx + 1
      if $curidx <= $maxidx
        printf ", "
      end
    end
    printf " )\n"
  end
  set $maxidx = 0
  set $curidx   = 0
end

set $SVf_IOK = 0x00000100
set $SVf_NOK = 0x00000200
set $SVf_POK = 0x00000400
set $SVf_ROK = 0x00000800


define printsv
  set $printsv_sv = $arg0
  if $printsv_sv
    if $printsv_sv->sv_flags & $SVf_ROK
        SvTYPE $printsv_sv->sv_u->svu_rv
        SvTYPE_print $printsv_sv->sv_u->svu_rv
        printf "(%p)",($printsv_sv)->sv_u->svu_rv
      else
        if $printsv_sv->sv_flags & $SVf_IOK
          printf "%d",($printsv_sv)->sv_u->svu_iv
        else
          if $printsv_sv->sv_flags & $SVf_NOK
            printf "%f",((XPVNV*)$printsv_sv->sv_any)->xnv_u.xnv_nv
          else
            if $printsv_sv->sv_flags & $SVf_POK
              printf "%s", ($printsv_sv)->sv_u->svu_pv
            else
              printf "undef"
            end
          end
        end
    end
  else
    printf "?NullSV?"
  end
end

define SvTYPE
  set $SvTYPE = ((svtype)(($arg0)->sv_flags & 0xff))
end

define SvTYPE_print
  set $SvTYPE = ((svtype)(($arg0)->sv_flags & 0xff))
  if $SvTYPE == SVt_PVAV
    printf "ARRAY"
  else
    if $SvTYPE == SVt_PVHV
      printf "HASH"
    else
      if $SvTYPE == SVt_PVCV
        printf "CV"
      else
        printf "SV"
      end
    end
  end
end

define printav
  if $argc == 0
    printf "Usage: printav 0x22c9be8 or printav 0x22c9be8 10"
  else
    set $printav_avmax   = ((AV*)$arg0)->sv_any->xav_max
    if $argc == 2
      set $printav_avmax = $arg1 - 1
    end

    set $printav_avfirst = ((AV*)$arg0)->sv_u->svu_array
    set $printav_cur     = 0

    while $printav_cur <= $printav_avmax
      set $printav_cursv = ($printav_avfirst + $printav_cur)
        printsv $printav_cursv
        printf "\n"
      set $printav_cur = $printav_cur + 1
    end
  end
end



define longmess
    getperl
    set $sv = Perl_eval_pv((void*)$perl,"require Carp; Carp::longmess()",0)
    printpv $sv
end
