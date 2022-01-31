-module(bcab).
-compile(export_all).

-define(PUERTO, "/dev/ttyACM0").

start() ->
    Arduino = open_port(?PUERTO, []),
    M = spawn(?MODULE, loop, [Arduino]),
    register(?MODULE, M),	
    port_connect(Arduino, M), 	
    Arduino.

encen_llum(Pis) ->
    ?MODULE!{light_ON, Pis}.
apaga_llum(PisP) ->
    ?MODULE!{light_OFF, PisP}.
display(M) ->
    ?MODULE!{mostra, M}.
final() ->
    ?MODULE!final.
final0() ->
    ?MODULE!final0.

loop(Arduino) ->
    receive
	{light_ON, Pis} ->
	    on(Arduino, Pis),
	    loop(Arduino);
	{light_OFF, PisP} ->
	    off(Arduino, PisP),
	    loop(Arduino);
	{mostra, M} ->
	    display(Arduino, M),
	    loop(Arduino);
	{Arduino, {data, Msg}} ->
	    bcab_fisic(Msg),
	    loop(Arduino);
	final0 ->
	    port_close(Arduino),
	    unregister(?MODULE),
	    ok;
	final ->
	    %port_close(Arduino),
	    unregister(?MODULE),
	    ok
    end.

on(Arduino, 5) ->
    port_command(Arduino, "E5");
on(Arduino, 4) ->
    port_command(Arduino, "E4");
on(Arduino, 3) ->
    port_command(Arduino, "E3");
on(Arduino, 2) ->
    port_command(Arduino, "E2");
on(Arduino, 1) ->
    port_command(Arduino, "E1");
on(Arduino, 0) ->
    port_command(Arduino, "E0");
on(_Arduino, Pis) ->
    io:format("No me sirve ~p\n", [Pis]).

off(Arduino, 5) ->
    port_command(Arduino, "A5");
off(Arduino, 4) ->
    port_command(Arduino, "A4");
off(Arduino, 3) ->
    port_command(Arduino, "A3");
off(Arduino, 2) ->
    port_command(Arduino, "A2");
off(Arduino, 1) ->
    port_command(Arduino, "A1");
off(Arduino, 0) ->
    port_command(Arduino, "A0");
off(_Arduino, Pis) ->
    io:format("No me sirve ~p\n", [Pis]).

display(Arduino, 5) ->
    port_command(Arduino, "D5");
display(Arduino, 4) ->
    port_command(Arduino, "D4");
display(Arduino, 3) ->
    port_command(Arduino, "D3");
display(Arduino, 2) ->
    port_command(Arduino, "D2");
display(Arduino, 1) ->
    port_command(Arduino, "D1");
display(Arduino, 0) ->
    port_command(Arduino, "D0");
display(_Arduino, Pis) ->
    io:format("No me sirve ~p\n", [Pis]).

bcab_fisic("B5\n") ->
    ascensor:boto_premut(5);
bcab_fisic("B4\n") ->
    ascensor:boto_premut(4);
bcab_fisic("B3\n") ->
    ascensor:boto_premut(3);
bcab_fisic("B2\n") ->
    ascensor:boto_premut(2);
bcab_fisic("B1\n") ->
    ascensor:boto_premut(1);
bcab_fisic("B0\n") ->
    ascensor:boto_premut(0);
bcab_fisic("TP\n") ->
    ascensor:tancar_bcab();
bcab_fisic("OP\n") ->
    ascensor:obrir_bcab();
bcab_fisic(Msg) ->
    io:format("No me sirve ~p\n", [Msg]).

