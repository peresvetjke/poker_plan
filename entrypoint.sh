#! /bin/sh

if [ $# -eq 0 ]; then
  _build/prod/rel/poker_plan/bin/migrate
  _build/prod/rel/poker_plan/bin/poker_plan start
else
  exec "$@"
fi
