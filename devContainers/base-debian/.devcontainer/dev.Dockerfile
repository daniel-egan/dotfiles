FROM debian:latest

RUN apt-get update && apt-get install -y sudo zsh git

COPY .zshrc /root/.zshrc