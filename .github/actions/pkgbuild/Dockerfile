FROM archlinux:base-devel

RUN useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY entrypoint.sh /entrypoint.sh

USER builder
HEALTHCHECK NONE

ENTRYPOINT ["/entrypoint.sh"]
