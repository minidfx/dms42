FROM elixir:1.10.2

LABEL Burgy Benjamin aka MiniDfx

# Ignore any console dialogs
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /app && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs\
                       tesseract-ocr\
                       tesseract-ocr-eng\
                       tesseract-ocr-fra\
                       xpdf\
		               graphicsmagick

# Elixir
COPY mix.exs mix.lock /app/
COPY lib/ /app/lib/
COPY config/ /app/config/
COPY priv/gettext/ /app/priv/gettext/
COPY priv/repo/ /app/priv/repo/

# Javascript
COPY assets/css/ /app/assets/css/
COPY assets/elm/ /app/assets/elm/
COPY assets/images/ /app/assets/images/
COPY assets/js/ /app/assets/js/
COPY assets/static/ /app/assets/static/
COPY assets/.babelrc /app/assets/.babelrc
COPY assets/package.json /app/assets/package.json
COPY assets/webpack.config.js /app/assets/webpack.config.js

WORKDIR /app

ENV MIX_ENV prod
ENV PORT 4001
ENV SECRET_KEY_BASE yxYFal4cla1dvXmA5A86JqRNSjpl87tdy3dR+bT4eGxpWwLGqCPMhtuza9ZXxNWB

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix compile
RUN npm install --prefix assets && \ 
    npm run deploy --prefix assets && \
    mix phx.digest

ENTRYPOINT mix ecto.create && \
	       mix ecto.migrate && \
           mix phx.server

EXPOSE 4001
