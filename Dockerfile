# The image you are going to inherit your Dockerfile from
FROM python:3.10.7-slim-buster
# Necessary, so Docker doesn't buffer the output and that you can see the output 
# of your application (e.g., Django logs) in real-time.
ENV PYTHONUNBUFFERED 1

# Sane defaults for pip
ENV PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Define ARGs
ARG ENVIRONMENT=local

COPY requirements/*.txt /tmp/requirements/

# Make a directory in your Docker image, which you can use to store your source code
RUN set -x \
    && apt-get update \
    && yes | apt-get install libexpat1=2.2.6-2+deb10u4 \
    && runDeps=" \
    postgresql-client \
    " \
    && echo "deb http://deb.debian.org/debian buster main contrib non-free" > /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && apt-get install -y --no-install-recommends $runDeps \
    # Install Python dependencies
    && pip install -r /tmp/requirements/base.txt \
    && if [ $ENVIRONMENT = local ]; then \
    # Install python dev dependencies
    pip install -r /tmp/requirements/test.txt \
    && pip install -r /tmp/requirements/base.txt; \
    # Install dependencies for graphviz
    # apt-get install graphviz graphviz-dev ttf-freefont; \
    else \
    # other environment to local remove the build dependencies
    apt-get remove -y $buildDeps; \
    fi \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Set the /app directory as the working directory
WORKDIR /app
# Copies from your local machine's current directory to the app folder 
# in the Docker image
COPY . .
# Copy the requirements.txt file adjacent to the Dockerfile 
# to your Docker image
COPY requirements/*.txt /tmp/requirements/
# add our user and group first to make sure their IDs get assigned consistently
RUN groupadd -r deployer && useradd -r -m -g deployer deployer && chown -R deployer:deployer /app

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]