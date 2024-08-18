# Build and run:
#
# docker build -t ace:12.0.4.0 -f Dockerfile .
# docker run -e LICENSE=accept -p 7600:7600 -p 7800:7800 --rm -ti ace:12.0.4.0
#
# Can also mount a volume for the work directory:
#
# docker run -e LICENSE=accept -v /what/ever/dir:/home/aceuser/ace-server -p 7600:7600 -p 7800:7800 --rm -ti ace:12.0.4.0
#
# This might require a local directory with the right permissions, or changing the userid further down . . .

FROM registry.access.redhat.com/ubi8/ubi-minimal

RUN microdnf update -y &&  \
    microdnf install util-linux openssl python3.9 sudo passwd vim openssh-server curl bc tar iputils procps net-tools tar hostname findutils less nano nc &&  \
    microdnf clean all

# Force reinstall tzdata package to get zoneinfo files
RUN microdnf reinstall tzdata -y