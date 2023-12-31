FROM python:3.10-alpine3.17 AS builder

ENV MOLECULE_VER=4.0.3

RUN set -eux \
        && apk add --update --no-cache \
                gcc \
                libc-dev \
                libffi-dev \
                make \
                musl-dev \
                openssl-dev \
        && pip install --no-cache-dir \
                cryptography==3.4.8 \
                ansible-lint \
                jmespath \
                "molecule[ansible,docker,lint]==$MOLECULE_VER" \
                yamllint

FROM python:3.9-alpine3.13

RUN set -eux \ 
        && apk add --update --no-cache \
                docker \
                git \
                openssh-client \
                && rm -rf /root/.cache

COPY --from=builder /usr/local/lib/python3.10/site-packages/ /usr/local/lib/python3.10/site-packages/
COPY --from=builder /usr/local/bin/molecule /usr/local/bin/molecule
COPY --from=builder /usr/local/bin/yamllint /usr/local/bin/yamllint
COPY --from=builder /usr/local/bin/ansible* /usr/local/bin/

CMD cd ${GITHUB_REPOSITORY} ; if [ "${M_COMMAND}" = "converge" ] && [ -n "${EXTRA_ARGS}" ] ; then echo "Ansible extra arguments: ${EXTRA_ARGS}" ; ASSEMBLED_CMD="molecule converge -s ${SCENARIO:-default} -- ${EXTRA_ARGS}" ; eval $ASSEMBLED_CMD; else molecule "${M_COMMAND}" -s ${SCENARIO:-default} ; fi
