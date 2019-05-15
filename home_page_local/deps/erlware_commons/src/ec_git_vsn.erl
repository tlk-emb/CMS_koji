%%% vi:ts=4 sw=4 et
%%%-------------------------------------------------------------------
%%% @author Eric Merritt <ericbmerritt@gmail.com>
%%% @copyright 2011 Erlware, LLC.
%%% @doc
%%%  This provides an implementation of the ec_vsn for git. That is
%%%  it is capable of returning a semver for a git repository
%%% see ec_vsn
%%% see ec_semver
%%% @end
%%%-------------------------------------------------------------------
-module(ec_git_vsn).

-behaviour(ec_vsn).

%% API
-export([new/0,
         vsn/1]).

-export_type([t/0]).

%%%===================================================================
%%% Types
%%%===================================================================
%% This should be opaque, but that kills dialyzer so for now we export it
%% however you should not rely on the internal representation here
-type t() :: {}.

%%%===================================================================
%%% API
%%%===================================================================

-spec new() -> t().
new() ->
    {}.

-spec vsn(t()) -> {ok, string()} | {error, Reason::any()}.
vsn(Data) ->
    {Vsn, RawRef, RawCount} = collect_default_refcount(Data),
    {ok, build_vsn_string(Vsn, RawRef, RawCount)}.

%%%===================================================================
%%% Internal Functions
%%%===================================================================

collect_default_refcount(Data) ->
    %% Get the tag timestamp and minimal ref from the system. The
    %% timestamp is really important from an ordering perspective.
    RawRef = os:cmd("git log -n 1 --pretty=format:'%h\n' "),

    {Tag, TagVsn} = parse_tags(Data),
    RawCount =
        case Tag of
            undefined ->
                os:cmd("git rev-list --count HEAD");
            _ ->
                get_patch_count(Tag)
        end,
    {TagVsn, RawRef, RawCount}.

build_vsn_string(Vsn, RawRef, RawCount) ->
    %% Cleanup the tag and the Ref information. Basically leading 'v's and
    %% whitespace needs to go away.
    RefTag = case RawRef of
                 undefined ->
                     "";
                 RawRef ->
                     [".ref", re:replace(RawRef, "\\s", "", [global])]
             end,
    Count = erlang:iolist_to_binary(re:replace(RawCount, "\\s", "", [global])),

    %% Create the valid [semver](http://semver.org) version from the tag
    case Count of
        <<"0">> ->
            erlang:binary_to_list(erlang:iolist_to_binary(Vsn));
        _ ->
            erlang:binary_to_list(erlang:iolist_to_binary([Vsn, "+build.",
                                                           Count, RefTag]))
    end.

get_patch_count(RawRef) ->
    Ref = re:replace(RawRef, "\\s", "", [global]),
    Cmd = io_lib:format("git rev-list --count ~s..HEAD",
                         [Ref]),
    os:cmd(Cmd).

-spec parse_tags(t()) -> {string()|undefined, ec_semver:version_string()}.
parse_tags({}) ->
    parse_tags("");
parse_tags(Pattern) ->
    Cmd = io_lib:format("git describe --abbrev=0 --tags --match \"~s*\"", [Pattern]),
    Tag = os:cmd(Cmd),
    Vsn = slice(Tag, len(Pattern)),
    Vsn1 = trim(trim(Vsn, left, "v"), right, "\n"),
    {Tag, Vsn1}.

-ifdef(unicode_str).
len(Str) -> string:length(Str).
trim(Str, right, Chars) -> string:trim(Str, trailing, Chars);
trim(Str, left, Chars) -> string:trim(Str, leading, Chars);
trim(Str, both, Chars) -> string:trim(Str, both, Chars).
slice(Str, Len) -> string:slice(Str, Len).
-else.
len(Str) -> string:len(Str).
trim(Str, Dir, [Chars|_]) -> string:strip(Str, Dir, Chars).
slice(Str, Len) -> string:substr(Str, Len + 1).
-endif.
