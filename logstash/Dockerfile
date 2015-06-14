FROM logstash:1.5
COPY conf /logstash/conf

COPY local-plugins /logstash/local-plugins
RUN /opt/logstash/bin/plugin install /logstash/local-plugins/logstash-filter-geocoder-0.1.0.gem
RUN chown logstash /opt/logstash/.bundle/config -R
