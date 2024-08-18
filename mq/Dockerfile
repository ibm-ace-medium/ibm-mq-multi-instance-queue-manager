FROM my-docker-repository/mq-install:9.3.5.0

ENV LOG_FILES_DIR_ENV=${LOG_FILES_DIR}
ENV DATA_FILES_DIR_ENV=${DATA_FILES_DIR}

COPY --chmod=774 --chown=mqm:mqm mq-setup.sh /home/mqm/mq-setup.sh
COPY --chmod=774 --chown=mqm:mqm mq-start.sh /home/mqm/mq-start.sh
COPY --chmod=774 --chown=mqm:mqm mq-setup.mqsc /home/mqm/mq-setup.mqsc
COPY --chmod=544 icc-shift.sh /etc/profile.d/icc-shift.sh
COPY --chmod=774 init.sh /var/scripts/init.sh

USER mqm:mqm

ENTRYPOINT ["/home/mqm/mq-start.sh", "QMgr01"]