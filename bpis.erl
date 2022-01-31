-module(bpis).
-include_lib("wx/include/wx.hrl").
-export([nou/1, bpis_proc/1, display/2, llum/3, final/1]).


-define(BUTTON_UP,   300).
-define(BUTTON_DOWN, 301).
-define(UNACTIVE_COLOR, {246,246,245}).
-define(ACTIVE_COLOR, {255,255,153}).


%% Funcions públiques

nou(Pis) ->
    spawn(?MODULE, bpis_proc, [Pis]).

display(Pid,M) ->
    Pid!{display,M}.

llum(Pid, Dir, si) ->
    Pid!{light_on, Dir};

llum(Pid, Dir, no) ->
    Pid!{light_off, Dir};

llum(_,_,_) -> 
    ok.

final(Pid) ->
    Pid!final.

%% -------------------------------

bpis_proc(Pis) ->
    wx:set_env(wxenv:get()),
    Frame = create_window(Pis),
    L = create_widgets(Frame),
    wxWindow:show(Frame),
    loop(Pis, Frame, L),
    ok.

create_window(Pis) ->
    Title   = io_lib:format("Pis ~b",[Pis]),
						%Frame = wxFrame:new(wx:null(), -1, Title),
    Frame = wxFrame:new(wx:null(), -1, Title, 
			[{size, {140, 180}},
			 {style, ?wxRESIZE_BORDER bor ?wxSYSTEM_MENU 
			      bor ?wxCAPTION bor ?wxCLOSE_BOX 
			      bor ?wxCLIP_CHILDREN}]), % window title
    wxFrame:connect(Frame, close_window),
    Frame.

create_widgets(Frame) ->

    Panel = wxPanel:new(Frame),

						% Create the sizer

						% Create the display and add it to sizer
    Display = wxTextCtrl:new(Panel, 100,
			     [{style,?wxTE_READONLY bor ?wxTE_RIGHT},
			      {pos,{10,10}}, {size, {100,22}},
			      {value, "0"}]),
    Redtext = wxTextAttr:new({255,10,10}),
    wxTextCtrl:setDefaultStyle(Display, Redtext),

						% Create open/close doors buttons
    UpB = wxButton:new(Panel, ?BUTTON_UP, [{label,"\x{2191}"},
					   {pos,{10,50}},{size, {100,22}}]),
    wxButton:setToolTip(UpB, "Puja"),
    DownB = wxButton:new(Panel, ?BUTTON_DOWN, [{label,"\x{2193}"},
					       {pos,{10,80}}, {size, {100,22}}]),
    wxButton:setToolTip(DownB, "Baixa"),
    wxButton:setBackgroundColour(UpB, ?UNACTIVE_COLOR),
    wxButton:setBackgroundColour(DownB, ?UNACTIVE_COLOR),
    wxButton:connect(UpB, command_button_clicked),
    wxButton:connect(DownB, command_button_clicked),
    wxFrame:show(Frame),
    {Display, UpB, DownB}.


loop(Pis, Frame, W) ->
    {Display, UpB, DownB} = W,
    receive 
   	#wx{event=#wxClose{}} ->
   	    io:format("Closing bpis ~b ~n",[Pis]),
	    wxWindow:destroy(Frame),
	    ascensor:abort(), % ********** S'ha de treure el % **************
	    ok;
   	#wx{id=?BUTTON_UP,
	    event=#wxCommand{type=command_button_clicked}} ->
	    ascensor:premut(Pis, amunt),  %%% UP % ********** S'ha de treure el % **************
	    loop(Pis, Frame, W);
   	#wx{id=?BUTTON_DOWN,
	    event=#wxCommand{type=command_button_clicked}} ->
	    ascensor:premut(Pis, avall), %%% DOWN % ********** S'ha de treure el % **************
	    loop(Pis, Frame, W);
 	final -> 
	    wxWindow:destroy(Frame),
	    ok;
	{light_on, F} ->
	    B = if F =:= amunt -> UpB; F =:= avall -> DownB end,
	    wxButton:setBackgroundColour(B, ?ACTIVE_COLOR),
	    loop(Pis, Frame, W);
	{light_off, F} ->
	    B = if F == amunt -> UpB; F == avall -> DownB end,
	    wxButton:setBackgroundColour(B, ?UNACTIVE_COLOR),
	    loop(Pis, Frame, W);
	{display, off} ->
						% switch off the display
	    wxTextCtrl:clear(Display),
	    loop(Pis, Frame, W);
	{display, V} when is_integer(V) ->
						% show V in the display
	    T = io_lib:format("~B",[V]),
	    wxTextCtrl:clear(Display),
	    wxTextCtrl:setValue(Display,T),
	    loop(Pis, Frame, W);
	{display, L} when is_list(L) ->
						% show V in the display
	    T = io_lib:format("~8s",[L]),
	    wxTextCtrl:clear(Display),
	    wxTextCtrl:setValue(Display,T),
	    loop(Pis, Frame, W);
	Msg ->
	    io:format("Botonera pis got unknown message ~p ~n", [Msg]),
	    loop(Pis, Frame, W)
    end.


