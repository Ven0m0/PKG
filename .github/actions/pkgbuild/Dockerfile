FROM archlinux:base-devel

RUN pacman -Syu --noconfirm --needed pacman-contrib && \
    useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY --chmod=755 entrypoint.sh /entrypoint.sh

USER builder
HEALTHCHECK NONE

ENTRYPOINT ["/entrypoint.sh"]
