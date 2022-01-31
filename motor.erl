-module(motor).
-compile(export_all).

-define(VELCAB, 1.5).
-define(RESOL, 100).
-define(RECMAX, 24).
-define(DELTA, (?VELCAB * (?RESOL / 1000))).

iniciMotor() ->
    register(?MODULE, spawn(?MODULE, loop, [0])).

pujar() ->
    motor!pujar.

baixar() ->
    motor!baixar.

aturar() ->
    motor!aturar.

final()->
    motor!final.

loop(Pos) ->
    receive
	pujar ->
	    up(Pos);
	baixar ->
	    down(Pos);
	aturar ->
	    loop(Pos);
	final ->
	    sensor:final(),
	    ok
    end.

up(P) ->
    receive
	aturar ->
	    loop(P);
	final ->
	    sensor:final(),
	    ok
    after
	?RESOL ->
	    if
		P > ?RECMAX ->
		    sensor:pmax(),
		    loop(P);
		true ->
		    Newpos = P + ?DELTA,
		    sensor:posicio(Newpos), 
		    up(Newpos)
	    end
    end.

down(P) ->
    receive
	aturar ->
	    loop(P);
	final -> 
	    sensor:final(),
	    ok
    after
	?RESOL ->
	    if
		P =< 0 ->
		    sensor:pmin(),
		    loop(P);
		true ->
		    Newpos = P - ?DELTA,
		    sensor:posicio(Newpos),
		    down(Newpos)
	    end
    end.
