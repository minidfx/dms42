FROM elixir:1.6

LABEL Burgy Benjamin aka MiniDfx

# Ignore any console dialogs
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /app && \
    curl -sL https://deb.nodesource.com/setup_9.x | bash - && \
    apt-get update && \
    apt-get install -y gcc make libtool-bin libgraphicsmagick1-dev inotify-tools nodejs && \
    npm install --unsafe-perm -g elm && \
    npm install -g brunch
    # add-apt-repository -y ppa:hvr/ghc  && \
    # apt-get update && \
    # apt-get install -y ghc-7.10.3 cabal-install-1.22 && \
    # cabal update && \
    # cabal install cabal-install --prefix=/usr/local && \
    # curl -sL https://raw.githubusercontent.com/elm-lang/elm-platform/master/installers/BuildFromSource.hs > BuildFromSource.hs

WORKDIR /app

VOLUME /app

EXPOSE 5000

RUN mix local.hex --force && \
    mix local.rebar --force

# RUN apt-get remove -y gcc make cabal-install

      # mix deps.get && \
#     mix deps.compile && \
#     pushd assets && \
#     npm install && \
#     brunch build
