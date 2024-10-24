####################################################################################################
## Builder
####################################################################################################
FROM rust:latest AS builder

RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev
RUN update-ca-certificates

# Create appuser
ENV USER=fishcannery
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"


WORKDIR /fishcannery

COPY ./ .

RUN cargo install dioxus-cli --target x86_64-unknown-linux-musl

RUN dx build --platform fullstack --target x86_64-unknown-linux-musl --release 

####################################################################################################
## Final image
####################################################################################################
FROM scratch

# Import from builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

WORKDIR /fishcannery

# Copy our build
COPY --from=builder /fishcannery/target/x86_64-unknown-linux-musl/release/fishcannery ./

# Use an unprivileged user.
USER fishcannery:fishcannery

CMD ["/fishcannery/fishcannery"]