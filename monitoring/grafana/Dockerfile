FROM grafana/grafana:6.7.2

COPY datasources.yaml /etc/grafana/provisioning/datasources/
COPY dashboards.yaml /etc/grafana/provisioning/dashboards/
COPY ./dashboards/* /etc/grafana/provisioning/dashboards_files/
