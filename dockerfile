FROM teddysun/xray:latest


WORKDIR /app
COPY . .
RUN rm /etc/xray/config_new.json
COPY config.json /etc/xray/config_new.json


CMD [ "/usr/bin/xray" ]
