-module(bppool).
-compile(export_all).

inici(N) ->
    process_flag(trap_exit, true),
    wxenv:inici(),
    register(?MODULE, spawn(?MODULE, reset, [0, N, []])).

iniciN(N) ->
    process_flag(trap_exit, true),
    register(?MODULE, spawn(?MODULE, reset, [0, N, []])).

reset(Count, N, Lista) when (Count > N - 1) ->
    loop(Lista);
reset(Count, N, Lista) ->
    Pis = bpis:nou(Count),
    link(Pis),
    reset(Count + 1, N, Lista++[Pis]).

display(N, M) ->
    bppool!{display, N, M}.

llum(Pis, Dir, E) ->
    bppool!{llum, Pis, Dir, E}.

eliminat() ->
    bppool!eliminat.

nth(1, [H|_]) ->    
    H;
nth(N, [_|T]) when is_integer(N), N > 1 -> 
    nth(N - 1, T).

loop(Pis_Pid) ->
    receive
	{display, N, M} ->
	    if N == tots ->
		    lists:map(fun(E)-> bpis:display(E, M) end, Pis_Pid), 
		    loop(Pis_Pid);
	       true->
		    bpis:display(nth(N + 1, Pis_Pid), M),
		    loop(Pis_Pid)
	    end;

	{llum, Pis, Dir, E} ->
	    if Dir == tots ->
		    bpis:llum(nth(Pis+1, Pis_Pid), amunt, E),
		    bpis:llum(nth(Pis+1, Pis_Pid), avall, E),
		    loop(Pis_Pid);
	       true->
		    bpis:llum(nth(Pis + 1, Pis_Pid), Dir, E),
		    loop(Pis_Pid)
	    end;

	eliminat ->
	    lists:map(fun(E)-> bpis:final(E) end, Pis_Pid),
	    ok;

	{'EXIT', _Pid, _Reason} ->
	    ascensor:abort();

	_ ->
	    loop(Pis_Pid)
    end.
