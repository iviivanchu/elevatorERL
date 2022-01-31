-module(ascensor).
-compile(export_all).

-define(Pisos, 6).

processMonitor() ->
    P = bcab:start(),
    monitor(port, P),
    link(whereis(motor)),
    link(whereis(sensor)),
    link(whereis(bppool)).

start() ->
    process_flag(trap_exit, true),
    register(?MODULE, self()),
    sensor:iniciSensor(),
    motor:iniciMotor(),
    bppool:inici(?Pisos),
    cporta:inici(),
    processMonitor(),
    reset().

pmax() ->
    ascensor!pos_max.

pmin() ->
    ascensor!pos_min.

envia_planta(P) ->
    ascensor!{planta, P}.

boto_premut(Pl) ->
    ascensor!{boto_premut, Pl}.

fi_bcab() ->
    ascensor!fi_bcab.

premut(Pis, _Bot) ->
    ascensor!{pis, Pis}.

abort() ->
    ascensor!fi_bpis.

porta_oberta() ->
    ascensor!porta_oberta.

porta_tancada() ->
    ascensor!porta_tancada.

tancant_porta() ->
    ascensor!tancant_porta.

obrir_bcab() ->
    ascensor!obrir_porta.

tancar_bcab() ->
    ascensor!tancar_porta.

fi_sporta() ->
    ascensor!fi_sporta.

puerto() ->
    ascensor!puerto.

reset() ->
    motor:baixar(),
    receive
	pos_min ->
	    motor:aturar(),
	    motor:pujar(),
	    receive
		{planta, 0} ->
		    bppool:display('tots', "OCUPAT"),
		    bppool:display(0, "AQUÍ"),
		    timer:sleep(2000),
		    bcab:encen_llum(0),
		    motor:aturar(),
		    stop_loop(0, 0, 0)
	    end
    end.

new_reset() ->
    motor:baixar(),
    receive
	pos_min ->
	    motor:aturar(),
	    motor:pujar(),
	    receive
		{planta, 0} ->
		    motor:aturar(),
		    bppool:iniciN(6),
		    bcab:encen_llum(0),
		    timer:sleep(1000),
		    bcab:display(0),
		    bppool:display('tots', "OCUPAT"),
		    bppool:display(0, "AQUÍ"),
		    stop_loop(0, 0, 0)
	    end
    end.

moving_loop(Org, Des, InOut) ->
    receive
	pos_max ->
	    stop_loop(?Pisos-1, ?Pisos-1, 0);

	pos_min ->
	    stop_loop(0, 0, 0);

	{planta, P} ->
	    if
		P =:= Des ->
		    motor:aturar(),
		    bcab:display(P),
		    bppool:display('tots', "OCUPAT"),
		    bppool:llum(P, tots, no),
		    bppool:display(P, "Obrint"),
		    cporta:obrir(),
		    bcab:encen_llum(Des),
		    stop_loop(P, Des, 1);
		P =/= Des  ->
		    bcab:display(P),
		    bppool:display('tots', "OCUPAT"),
		    if
			InOut =:= 1 ->
			    bppool:display(Des, P);
			true ->
			    null
		    end,
		    moving_loop(Org, Des, InOut)
	    end;

	fi_bpis ->
	    bcab:apaga_llum(Des),
	    cporta:tancar(),
	    bppool:eliminat(),
	    new_reset();

	fi_sporta ->
	    bppool:eliminat(),
	    bcab:final(),
	    motor:final(),
	    wxenv:final(),
	    cporta:final(),
	    unregister(?MODULE),
	    erlang:flush(),
	    ok;

	{'DOWN', Reference, port, _Pid, _Reason} ->
	    bppool:display('tots', "AVERIA"),
	    motor:aturar(),
	    bcab:final(),
	    demonitor(Reference),
	    startt(),
	    bppool:display('tots', "OCUPAT"),
	    if
		Des > Org ->
		    motor:pujar();
		true ->
		    motor:baixar()
	    end,
	    moving_loop(Org, Des, InOut);

	{'EXIT', Pid, _Reason} ->
	    case Pid of
		motor ->
		    bcab:apaga_llum(Des),
		    cporta:tancar(),
		    motor:iniciMotor(),
		    reset(),
		    monitor(process, motor);
		sensor ->
		    bcab:apaga_llum(Des),
		    cporta:tancar(),
		    motor:aturar(),
		    sensor:iniciSensor(),
		    reset(),
		    monitor(process, sensor);
		bppool ->
		    bcab:apaga_llum(Des),
		    cporta:tancar(),
		    motor:aturar(),
		    new_reset(),
		    monitor(process, bppool);
		_ ->
		    ok
	    end,
	    moving_loop(Org, Des, InOut);

	_ ->
	    moving_loop(Org, Des, InOut)
    end.

startt() ->
    try port_close(open_port("/dev/ttyACM0", [])) of
	_ ->
	    P = bcab:start(),
	    monitor(port, P)
    catch
	error:einval ->
	    timer:sleep(1000),
	    startt()
    end.

stop_loop(Org, Des, Porta) ->
    receive
	{boto_premut, Pl} when Porta == 0 ->
	    bcab:encen_llum(Pl),
	    if
		Pl =:= Org ->
		    motor:aturar(),
		    bcab:display(Pl),
		    stop_loop(Org, Pl, 1);
		Pl > Org ->
		    bcab:apaga_llum(Org),
		    motor:pujar(),
		    moving_loop(Org, Pl, 0);
		Pl < Org ->
		    bcab:apaga_llum(Org),
		    motor:baixar(),
		    moving_loop(Org, Pl, 0)
	    end;

	{boto_premut, Pl} when Porta == 1 ->
	    bcab:encen_llum(Pl),
	    bcab:apaga_llum(Org),
	    cporta:tancar(),
	    bppool:display(Org, "Tancant"),
	    receive
		porta_tancada ->
		    if
          		Pl =:= Org ->
          		    motor:aturar(),
          		    bcab:display(Pl),
          		    stop_loop(Org, Pl, 1);
          		Pl > Org ->
          		    %bcab:apaga_llum(Org),
          		    motor:pujar(),
          		    moving_loop(Org, Pl, 0);
          		Pl < Org ->
          		    %bcab:apaga_llum(Org),
          		    motor:baixar(),
          		    moving_loop(Org, Pl, 0)
          	    end
	    end;

	{pis, Pis} when Porta == 0 ->
	    bppool:llum(Pis, tots, si),
	    if
    		Pis =:= Org ->
    		    motor:aturar(),
    		    bcab:display(Pis),
    		    bppool:llum(Pis, tots, no),
		    bppool:display(Pis, "Obrint"),
		    cporta:obrir(),
    		    stop_loop(Org, Pis, 1);
    		Pis > Org ->
    		    bcab:apaga_llum(Org),
    		    motor:pujar(),
    		    moving_loop(Org, Pis, 1);
    		Pis < Org ->
    		    bcab:apaga_llum(Org),
    		    motor:baixar(),
    		    moving_loop(Org, Pis, 1)
    	    end;

        fi_bpis ->
	    bcab:apaga_llum(Des),
	    cporta:tancar(),
	    bppool:eliminat(),
	    new_reset();

	fi_sporta ->
	    bppool:eliminat(),
	    bcab:final0(),
	    motor:final(),	    
	    wxenv:final(),
	    cporta:final(),
	    unregister(?MODULE),
	    erlang:flush(),
	    ok;

	{'DOWN', Reference, port, _Pid, _Reason} ->
	    bppool:display('tots', "AVERIA"),
	    cporta:tancar(),
	    motor:aturar(),
	    bcab:final(),
	    demonitor(Reference),
	    startt(),
	    bppool:display('tots', "OCUPAT"),
	    bppool:display(Org, "AQUI"),
	    timer:sleep(2000),
	    bcab:display(Org),
	    bcab:encen_llum(Org),
	    stop_loop(Org, Des, Porta);

	{'EXIT', Pid, _Reason} ->
	    case Pid of
		motor ->
		    bcab:apaga_llum(Des),
		    cporta:tancar(),
		    motor:iniciMotor(),
		    reset(),
		    monitor(process, motor);
		sensor ->
		    bcab:apaga_llum(Des),
		    cporta:tancar(),
		    motor:aturar(),
		    sensor:iniciSensor(),
		    reset(),
		    monitor(process, sensor);
		bppool ->
		    bcab:apaga_llum(Des),
		    cporta:tancar(),
		    motor:aturar(),
		    new_reset(),
		    monitor(process, bppool);
		_ ->
		    ok
	    end,
	    stop_loop(Org, Des, Porta);

	%%Cporta
	tancant_porta ->
	    bppool:display(Org, "Tancant"),
	    stop_loop(Org, Des, 1);

	porta_oberta ->
	    bppool:display(Org, "Obert"),
	    stop_loop(Org, Des, 1);

	porta_tancada ->
	    timer:sleep(1000),
	    bppool:display(Org, "AQUÍ"),
	    stop_loop(Org, Des, 0);

	%%Bcab
	obrir_porta ->
	    bppool:display(Org, "Obrint"),
	    cporta:obrir(),
	    stop_loop(Org, Des, 1);

	tancar_porta ->
	    bppool:display(Org, "Tancant"),
	    cporta:tancar(),
	    stop_loop(Org, Des, 1);

	_ ->
	    stop_loop(Org, Des, Porta)
    end.
