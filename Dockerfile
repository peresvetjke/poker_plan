FROM libertas.art.rambler.ru/elixir:1.14.3-alpine AS build

# Set exposed ports
EXPOSE 4000
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Install build dependencies
# RUN apk add --update --no-cache build-base git nodejs npm
RUN apk update && apk upgrade && apk add npm curl bash

# Copy the Phoenix project to the container
WORKDIR /app
COPY . .

# Add group and user
RUN addgroup -S -g 1001 poker_plan && \
  adduser -S -D -u 1001 -G poker_plan poker_plan && \
  chown -R poker_plan:poker_plan /app
USER poker_plan:poker_plan

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

# Cache elixir deps
# ADD mix.exs mix.lock ./

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force
# Load and compile dependencies
RUN mix deps.get && mix deps.compile
# Prepare npm deps
RUN npm run deploy
# Prepare static files and build release
RUN mix phx.digest && mix release

# Create a release image
FROM build
USER poker_plan:poker_plan
# RUN apk add --no-cache openssl
# CMD ["_build/prod/rel/poker_plan/bin/poker_plan", "start"]

COPY --from=build /app/_build/prod/rel/poker_plan .
COPY --from=build /app/entrypoint.sh .

RUN chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
