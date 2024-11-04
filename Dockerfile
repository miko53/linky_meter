ARG RUBY_VERSION=3.3.1

FROM ruby:${RUBY_VERSION}-alpine

ENV TZ="Europe/Paris"

RUN adduser -g "ruby" -h "/home/ruby" -s "/dev/null" -D ruby

RUN apk add --no-cache build-base tzdata libc6-compat

WORKDIR /home/ruby/app

COPY . .
RUN gem install bundler
RUN gem install *.gem

RUN ln -s /home/ruby/app/bin/parser.sh /usr/local/bin/parser \
    && chmod +x /home/ruby/app/bin/parser.sh
RUN ln -s /home/ruby/app/bin/parserPower.sh /usr/local/bin/parserPower \
    && chmod +x /home/ruby/app/bin/parserPower.sh

RUN ln -s /home/ruby/app/bin/server.sh /usr/local/bin/server \
    && chmod +x /home/ruby/app/bin/server.sh

USER ruby

CMD ["server"]
