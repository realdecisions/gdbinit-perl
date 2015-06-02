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
    if (int)$max_stack <= 0
    	set $max_stack = $arg0
    end
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

define longmess
    getperl
    set $sv = Perl_eval_pv((void*)$perl,"require Carp; Carp::longmess()",0)
    printpv $sv
end
