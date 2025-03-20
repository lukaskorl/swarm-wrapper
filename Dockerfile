FROM alpine:latest

# Install docker CLI
RUN apk add --no-cache docker-compose

# Copy your script
COPY --chmod=700 entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
