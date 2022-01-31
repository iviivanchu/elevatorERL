-module(sporta).
-include_lib("wx/include/wx.hrl").
-export([nou/0, pos_porta/1, final/0, porta/0]).


-define(PORTA_ESQ,   300).
-define(PORTA_DRE,	301).
-define(MAX_PORTA,	130).
-define(UNACTIVE_COLOR, {246,246,245}).
-define(ACTIVE_COLOR, {255,155,153}).


%% Funcions públiques

nou() ->
    case whereis(wxenv) of
	undefined -> wxenv:start();
	_M -> ok
    end,
    register(porta,spawn(?MODULE, porta, [])).

pos_porta(Pos) ->
    porta!{posicio,Pos}.

final() ->
    porta!final.

%% -------------------------------

porta() ->
    wx:set_env(wxenv:get()),
    Frame = create_window(),
    L = create_widgets(Frame),
    wxWindow:show(Frame),
    loop(Frame, L),
    ok.

create_window() ->
    Title   = io_lib:format("Porta",[]),
    Frame = wxFrame:new(wx:null(), -1, Title,
			[{size, {295, 360}},
			 {style, ?wxSYSTEM_MENU
			      bor ?wxCAPTION bor ?wxCLOSE_BOX
			      bor ?wxCLIP_CHILDREN}]), % window title
    wxFrame:connect(Frame, close_window),
    Frame.

create_widgets(Frame) ->

    Panel = wxPanel:new(Frame),
    wxPanel:setBackgroundColour(Panel, ?UNACTIVE_COLOR),

						% Create the sizer

						% Create the display and add it to sizer, label : unicode

    DreP = wxPanel:new(Panel, 10, 10, 130, 305),
    wxPanel:setBackgroundColour(DreP, ?ACTIVE_COLOR),
    DreF = wxPanel:new(DreP, 90, 30, 30, 200),
    wxPanel:setBackgroundColour(DreF, ?UNACTIVE_COLOR),
    EsqP = wxPanel:new(Panel, 140,10, 130, 305),
    wxPanel:setBackgroundColour(EsqP, ?ACTIVE_COLOR),
    EsqF = wxPanel:new(EsqP, 10, 30, 30, 200),
    wxPanel:setBackgroundColour(EsqF, ?UNACTIVE_COLOR),
    wxFrame:show(Frame),
    {DreP, EsqP}.


loop(Frame, W) ->
    {DreP, EsqP} = W,
    receive
   	#wx{event=#wxClose{}} ->
   	    io:format("Closing porta ~n",[]),
	    wxWindow:destroy(Frame),
	    ascensor:fi_sporta(),
	    ok;
	final ->
	    wxWindow:destroy(Frame),
	    ok;
	{posicio, Pos} when Pos =< ?MAX_PORTA, Pos >= 0 ->
	    wxPanel:move(DreP, 10-Pos, 10),
	    wxPanel:move(EsqP, 140+Pos, 10),
	    loop(Frame, W);
	true ->
	    loop(Frame, W)

    end.
