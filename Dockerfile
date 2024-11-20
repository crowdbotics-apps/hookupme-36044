# Build stage for Python dependencies
FROM crowdbotics/cb-django:3.8-slim-buster AS build

# Copy dependency management files and install app packages to /.venv
COPY backend/Pipfile backend/Pipfile.lock /
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy

# Release stage
FROM crowdbotics/cb-django:3.8-slim-buster AS release

# Install necessary system dependencies
RUN apt-get update \
    && apt-get install -y \
        python3-pip \
        python3-cffi \
        python3-brotli \
        libpango-1.0-0 \
        libharfbuzz0b \
        libpangoft2-1.0-0 \
        libcairo2 \
        libpq-dev \
        libpangocairo-1.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG SECRET_KEY

# Set working directory
WORKDIR /opt/webapp

# Add runtime user with respective permissions
RUN groupadd -r django \
    && useradd -d /opt/webapp -r -g django django \
    && chown django:django -R /opt/webapp
USER django

# Copy app source from build stage
COPY --chown=django:django ./backend .

# Copy the virtual environment
COPY --from=build /.venv /.venv

# Set environment variables for the virtual environment
ENV PATH="/.venv/bin:$PATH"

# Collect static files and serve the app
RUN python3 manage.py collectstatic --no-input

# Command to run the application
CMD waitress-serve --port=$PORT hookupme_36044.wsgi:application
