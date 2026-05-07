FROM alpine:3.22@sha256:310c62b5e7ca5b08167e4384c68db0fd2905dd9c7493756d356e893909057601 AS builder

ARG OCAML_VERSION=5.1.0
ARG GGHCOMMITSHA=unknown
ENV GGHCOMMITSHA=$GGHCOMMITSHA

RUN apk add --no-cache opam ocaml ca-certificates build-base m4 make binutils

WORKDIR /build/
ENV OPAMSWITCH=/build

COPY dune-project ggh.opam .
COPY dune.lock dune.lock

RUN opam init --no-setup --disable-sandboxing --bare && \
    opam switch create $OPAMSWITCH $OCAML_VERSION --no-install && \
    opam install --switch $OPAMSWITCH . --yes --deps-only

COPY bin/ bin/
COPY lib lib/

RUN opam exec --switch $OPAMSWITCH -- \
    dune build \
    --release --sandbox none --force && \
    mv ./_build/default/bin/main.exe ./ggh

FROM alpine:3.22@sha256:310c62b5e7ca5b08167e4384c68db0fd2905dd9c7493756d356e893909057601

RUN apk add --no-cache git

RUN apk add --no-cache bash git openssh-client ca-certificates binutils \
    && rm -rf /var/cache/apk/* && update-ca-certificates

ENV HOOKDIR=/usr/share/ggh/

COPY --from=builder /build/ggh /usr/bin/ggh
RUN mkdir -p $HOOKDIR && /usr/bin/ggh print-hooks | while read -r hook; do \
    ln -sf /usr/bin/ggh $HOOKDIR/$hook; done

RUN git config set --system core.hooksPath $HOOKDIR

ENTRYPOINT ["/usr/bin/ggh"]