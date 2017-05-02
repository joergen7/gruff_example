-module( example ).
-behavior( application ).
-behavior( supervisor ).

-export( [start/0, stop/0, add/2, square/1] ).
-export( [start/2, stop/1] ).
-export( [init/1] ).

start() -> application:start( ?MODULE ).

stop() -> application:stop( ?MODULE ).

add( A, B ) ->
  F = fun( Wrk ) ->
        gen_server:call( Wrk, {add, A, B} )
      end,
  gruff:transaction( add, F ).

square( X ) ->
  F = fun( Wrk ) ->
        gen_server:call( Wrk, {square, X} )
      end,
  gruff:transaction( square, F ).

start( _StartType, _StartArgs ) ->
  supervisor:start_link( {local, example_sup}, ?MODULE, [] ).

stop( _State ) -> ok.

init( [] ) ->

    {ok, PoolLst} = application:get_env( example, pool_lst ),

    ChildSpecs = [#{ id      => Id,
                     start    => {gruff, start_link, [{local, Id},
                                                      {WrkMod, start_link, []},
                                                      Size]},
                     restart  => permanent,
                     shutdown => 5000,
                     type     => worker,
                     modules  => [gruff]
                   } || #{ id   := Id,
                           size := Size,
                           mod  := WrkMod
                         } <- PoolLst],

    SupFlags = #{ strategy  => one_for_one,
                  intensity => 10,
                  period    => 10 },

    {ok, {SupFlags, ChildSpecs}}.