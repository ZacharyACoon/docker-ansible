ARG GIT_REPO=https://github.com/ansible/ansible.git
ARG GIT_REF=stable-2.12


# FROM python:3.10.4-bullsey3
FROM python@sha256:000fb6161b50ed0d76e397573b1e189a4d7b8d6b781f082228f1d9d10298cd6a as base
RUN \
  apt-get -qq update && \
  apt-get -qq upgrade


FROM base as build
ARG GIT_REPO
ARG GIT_REF

# ansible needs symlink support, doesn't support zip, so we use git
RUN apt-get -qq install --no-install-suggests --no-install-recommends git
RUN \
  echo ${GIT_REPO} && \
  git clone ${GIT_REPO} /ansible && \
  cd /ansible && \
  git checkout ${GIT_REF}
RUN \
  mkdir /ansible/wheels/ && \
  pip wheel /ansible --wheel-dir /ansible/wheels/


FROM base as run
COPY --from=build /ansible/wheels/ /ansible/wheels
ENV PATH /opt/ansible_venv/bin/:$PATH
RUN \
  python -m venv /opt/ansible_venv && \
  python -m pip install --upgrade pip && \
  pip install --no-index --find-links /ansible/wheels/ ansible-core && \
  pip install docker paramiko && \
  ansible-galaxy collection install \
    community.general \
    community.docker \
    ansible.posix \
    && \
  ansible-galaxy role install \
    staticdev.firefox

RUN \
  apt-get -qq install --no-install-suggests --no-install-recommends \
  nano \
  rsync \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ENV PATH /opt/ansible_venv/bin:$PATH
WORKDIR /ansible
CMD ansible all --list-hosts
