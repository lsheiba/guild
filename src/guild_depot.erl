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

-module(guild_depot).

-export([accounts/1, account_projects/1]).

accounts(Depot) ->
    {ok, AccountDirs} = file:list_dir(data_dir(Depot)),
    [account(Depot, Dir) || Dir <- AccountDirs].

data_dir(Depot) ->
    filename:join(Depot, "data").

account(Depot, Name) ->
    #{name        => Name,
      depot       => Depot,
      source_path => account_dir(Depot, Name)}.

account_dir(Depot, Name) ->
    filename:join(data_dir(Depot), Name).

account_projects(#{source_path:=AccountDir}=Account) ->
    {ok, ProjectDirs} = file:list_dir(AccountDir),
    lists:foldl(
      fun(Dir, Acc) -> try_project_acc(Account, Dir, Acc) end,
      [], ProjectDirs).

try_project_acc(Account, Dir, Acc) ->
    case project(Account, Dir) of
        {ok, Project} ->
            [Project|Acc];
        {error, Err} ->
            #{name:=AccountName} = Account,
            guild_log:internal(
              "Error loading project ~s/~s: ~p~n",
              [AccountName, Dir, Err]),
            Acc
    end.

project(Account, Dir) ->
    case guild_project:from_dir(project_dir(Account, Dir)) of
        {ok, Project} -> {ok, depot_project(Project, Dir, Account)};
        {error, Err} -> {error, Err}
    end.

project_dir(#{source_path:=AccountDir}, Dir) ->
    filename:join(AccountDir, Dir).

depot_project(P, Dir, Account) ->
    #{
       path => project_path(Account, Dir),
       name => project_name(P, Dir),
       description => project_description(P),
       account => Account,
       source_path => guild_project:project_dir(P)}.

project_path(#{name:=Account}, Dir) ->
    Account ++ "/" ++ Dir.

project_name(P, Default) ->
    case guild_project:attr(P, ["project"], "name") of
        {ok, Name} -> Name;
        error -> Default
    end.

project_description(P) ->
    case guild_project:attr(P, ["project"], "description") of
        {ok, Desc} -> Desc;
        error -> ""
    end.
