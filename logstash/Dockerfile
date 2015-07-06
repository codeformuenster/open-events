FROM jruby

WORKDIR /opt/logstash-filter-geocoder
RUN curl -SL https://github.com/jsvd/logstash-filter-geocoder/archive/master.tar.gz \
  | tar -xz -C /opt/logstash-filter-geocoder --strip-components 1

ENV LOGSTASH_VERSION v1.5.1

WORKDIR /opt/logstash
RUN curl -SL https://github.com/elastic/logstash/archive/$LOGSTASH_VERSION.tar.gz \
  | tar -xz -C /opt/logstash --strip-components 1

RUN rake bootstrap \
  && bundle install --system --jobs 4

RUN bin/plugin install --no-verify fingerprint

RUN echo 'gem "logstash-filter-geocoder", :path => "/opt/logstash-filter-geocoder"' \
    >> Gemfile \
  && bin/plugin install --no-verify

RUN mkdir -p /opt/logstash/conf

COPY conf /opt/logstash/conf

CMD ["bin/logstash", "-f", "conf/*.conf"]
EXPOSE "7001"
