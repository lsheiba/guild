%% Copyright 2106 TensorHub, Inc.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(guild_serve_cmd).

-export([parser/0, main/2]).

-define(default_port, 6444).

%% ===================================================================
%% Parser
%% ===================================================================

parser() ->
    cli:parser(
      "guild view",
      "[OPTION]... [RUNDIR]",
      "Serve a trained model in RUNDIR or the latest using --latest-run.\n."
      "\n"
      "Use 'guild list-runs' to list runs that can be used for RUNDIR.",
      serve_options() ++ guild_cmd_support:project_options([latest_run]),
      [{pos_args, {0, 1}}]).

serve_options() ->
    [{port, "-p, --port",
      fmt("HTTP server port (default is ~b)", [?default_port]),
      [{metavar, "PORT"}]}].

fmt(Msg, Data) -> io_lib:format(Msg, Data).

%% ===================================================================
%% Main
%% ===================================================================

main(Opts, Args) ->
    {Run, Project, _, _} = guild_cmd_support:run_for_args(Args, Opts),
    guild_app:init_support([json, exec]),
    Server = start_http_server(Project, Run, Opts),
    wait_for_server_and_terminate(Server).

start_http_server(Project, Run, Opts) ->
    Port = guild_cmd_support:port_opt(Opts, ?default_port),
    Server = start_server(Project, Run, Port),
    guild_cli:out("Serving model on port ~b~n", [Port]),
    Server.

start_server(Project, Run, Port) ->
    case guild_model_serve_http:start_server(Project, Run, Port) of
        {ok, Server} ->
            Server;
        {error, {{listen, eaddrinuse}, _Stack}} ->
            port_in_use_error(Port)
    end.

port_in_use_error(Port) ->
    guild_cli:cli_error(
      io_lib:format(
        "port ~b is being used by another application\n"
        "Try 'guild serve --port PORT' with a different port.",
        [Port])).

wait_for_server_and_terminate(Pid) ->
    guild_proc:reg(Pid),
    Exit = guild_proc:wait_for({proc, Pid}),
    handle_server_exit(Exit).

handle_server_exit({_, normal}) ->
    guild_cli:out("Server stopped by user~n");
handle_server_exit({_, Other}) ->
    {error, io_lib:format("Unexpected server exit: ~p", [Other])}.
