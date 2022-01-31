-module(cporta).
-compile(export_all).

-define(T_OPEN, 31).
-define(T_WAIT, 10000).
-define(MAX_P, 130).
-define(MIN_P, 0).

inici() ->
    sporta:nou(),
    register(?MODULE, spawn(?MODULE, loop, [0])).

obrir() ->
  ?MODULE!obrir.

tancar() ->
  ?MODULE!tancar.

final() ->
  ?MODULE!fi.

loop(P) ->
  receive
    obrir ->
      obrir(P);
    tancar ->
      tancar(P);
    fi ->
      %sporta:final(),
      ok
  end.

obrir(P) ->
  receive
    tancar ->
      tancar(P);
    fi ->
      %sporta:final(),
      ok
  after
    ?T_OPEN ->
      if
        P >= ?MAX_P ->
          ascensor:porta_oberta(),
          apertura(P);
        true ->
          sporta:pos_porta(P),
          obrir(P + 1)
      end
  end.

apertura(P) ->
  receive
    tancar ->
      tancar(P);
    obrir ->
      apertura(P);
    fi ->
      %sporta:final(),
      ok
  after
    ?T_WAIT ->
      ascensor:tancant_porta(),
      tancar(P)
  end.

tancar(P) ->
  receive
    obrir ->
      obrir(P);
    fi ->
      %sporta:final(),
      ok
  after
    ?T_OPEN ->
      if
        P =< ?MIN_P ->
          ascensor:porta_tancada(),
          loop(0);
        true ->
          sporta:pos_porta(P),
          tancar(P - 1)
      end
  end.
