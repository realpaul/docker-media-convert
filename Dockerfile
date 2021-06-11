FROM debian:buster-slim

RUN echo "deb http://mirrors.163.com/debian buster main\ndeb http://mirrors.163.com/debian-security buster/updates main\ndeb http://mirrors.163.com/debian buster-updates main" > /etc/apt/sources.list \
  && cat /etc/apt/sources.list \
  && apt-get update -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    imagemagick ffmpeg exiftool jhead \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean -y \
  && apt-get autoremove -y \
  && mkdir -p /data

ADD convert.sh /data/convert.sh
ENTRYPOINT ["/data/convert.sh"]