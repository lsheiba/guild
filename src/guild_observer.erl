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

-module(guild_observer).

-export([maybe_start_from_global_opts/1]).

maybe_start_from_global_opts(Opts) ->
    maybe_start_observer(proplists:get_bool(observer, Opts)).

maybe_start_observer(true) ->
    observer:start(),
    guild_proc:reg(global, observer);
maybe_start_observer(false) ->
    ok.