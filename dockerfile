FROM teddysun/xray:latest


WORKDIR /app
COPY . .
RUN rm /etc/xray/config.json
COPY config-xhttp.json /etc/xray/config.json


CMD [ "/usr/bin/xray" ]
