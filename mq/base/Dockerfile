FROM my-docker-repository/rhel-base
VOLUME /home

# can solve problem for creating keystore on AMD processors. https://github.com/ibm-messaging/mq-container/issues/462
ENV ICC_SHIFT=3

RUN groupadd --gid 1010 mqm
RUN groupadd --gid 2000 mqadmins
RUN useradd --uid 1010 --gid mqm -s /bin/bash --create-home --home-dir /home/mqm mqm
RUN usermod -G mqm root

# important, don't put mqexplorer user into mqm group or mqexplorer will not work
RUN useradd --uid 3000 --groups mqadmins -s /bin/bash --create-home --home-dir /home/mqexplorer mqexplorer

# The URL to download the MQ installer from in tar.gz format
ARG MQ_FILE=9.3.5.0-IBM-MQ-Advanced-for-Developers-LinuxX64.tar.gz
#ARG MQ_URL=https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/$MQ_FILE
ARG MQ_URL=http://192.168.15.12:9000/$MQ_FILE
ARG MQ_PACKAGES="./MQSeriesJRE-*.x86_64.rpm ./MQSeriesRuntime-*.x86_64.rpm ./MQSeriesGSKit-*.x86_64.rpm ./MQSeriesServer-*.x86_64.rpm ./MQSeriesJava-*.x86_64.rpm ./MQSeriesSamples-*.x86_64.rpm"

  # Setting default shell to bash for new users \
RUN  sed -i 's/SHELL=\/bin\/sh/SHELL=\/bin\/bash/g' /etc/default/useradd \
  # Download and extract the MQ installation files \
  && mkdir -p /tmp/mq \
  && cd /tmp/mq \
  && curl -LO $MQ_URL \
  && tar -zxvf ./*.tar.gz \
  && cd /tmp/mq/MQServer \
  #   Accept the MQ license
  && ./mqlicense.sh -text_only -accept \
  #   Install MQ using the DEB packages
  && rpm -Uvh $MQ_PACKAGES \
  #   Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
  && /opt/mqm/bin/setmqinst -p /opt/mqm -i \
  # Cleanup
  && rm -rf /tmp/mq \
  && rm -rf /var/lib/apt/lists/*

# setting process and file open limits
RUN  echo "mqm             hard    nofile          10240" >> /etc/security/limits.conf
RUN  echo "mqm             soft    nofile          10240" >> /etc/security/limits.conf
RUN  echo "mqm             hard    nproc           30720" >> /etc/security/limits.conf
RUN  echo "mqm             soft    nproc           30720" >> /etc/security/limits.conf

ENTRYPOINT ["bash", "-c", "sleep 600"]