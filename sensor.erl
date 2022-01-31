-module (sensor).
-compile(export_all).

-define(PLANTES,{0, 0.5, 6.5, 10.5, 14.5, 18.5, 22.5}).

iniciSensor() ->
    register(?MODULE, spawn(?MODULE, loop, [1])).

pmax() ->
    sensor!pos_max.

pmin() ->
    sensor!pos_min.

posicio(P) ->
    sensor!{pos, P}.

final() ->
    sensor!final.

loop(Planta) ->
    receive
	{pos, P} ->
	    if
		(P > element(Planta, ?PLANTES)), (P >= element(Planta + 1, ?PLANTES)) ->
  		    ascensor!{planta, Planta - 1},
  		    loop(Planta + 1);

		(P < element(Planta, ?PLANTES)), (P =< element(Planta - 1, ?PLANTES)) ->
		    ascensor!{planta, Planta - 3},
		    loop(Planta - 1);
		true ->
		    loop(Planta)
	    end;

	pos_max ->
	    ascensor:pmax(),
	    loop(Planta);

	pos_min ->
	    ascensor:pmin(),
	    loop(Planta);

	final ->
	    ok
    end.
