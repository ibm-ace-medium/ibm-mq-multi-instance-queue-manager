FROM registry.access.redhat.com/ubi8/ubi-minimal

RUN microdnf update -y &&  \
    microdnf install util-linux openssl python3.9 sudo passwd vim openssh-server curl bc tar iputils procps net-tools tar hostname findutils less nano nc &&  \
    microdnf clean all

# Force reinstall tzdata package to get zoneinfo files
RUN microdnf reinstall tzdata -y