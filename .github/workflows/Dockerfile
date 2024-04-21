FROM mcr.microsoft.com/devcontainers/base:jammy AS lama

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install gcc-multilib opam xdot git

USER vscode
RUN mkdir -p /home/vscode
RUN git clone https://github.com/PLTools/Lama.git /home/vscode/lama
WORKDIR /home/vscode/lama

RUN opam init --disable-sandboxing
RUN opam switch create lama --packages=ocaml-variants.4.14.0+options,ocaml-option-flambda

ARG OPAMSWITCH=lama
RUN eval $(opam env)
RUN opam install /home/vscode/lama --yes
RUN echo "eval $(opam env)" >> /home/vscode/.bashrc

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install gdb