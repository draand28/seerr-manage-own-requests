# A patched Seerr image adding the "Manage Own Requests" permission.
# It clones upstream Seerr at a pinned commit, applies patches/, then builds.

ARG NODE_IMAGE=node:22.23.2-alpine3.23

FROM ${NODE_IMAGE} AS base
ARG SEERR_REF=e9590629b8215676a352ec2413d7c8ee7e6974df
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && apk add --no-cache git
WORKDIR /app
RUN git clone https://github.com/seerr-team/seerr.git . \
  && git fetch --depth 1 origin "${SEERR_REF}" \
  && git checkout --detach FETCH_HEAD
COPY patches/ /tmp/patches/
RUN git apply --verbose /tmp/patches/*.patch && rm -rf .git

FROM base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store CI=true pnpm install --prod --frozen-lockfile

FROM base AS build
ARG TARGETPLATFORM
RUN case "${TARGETPLATFORM}" in \
  'linux/arm64' | 'linux/arm/v7') \
  apk add --no-cache python3 make g++ gcc libc6-compat bash && \
  npm install --global node-gyp \
  ;; esac
RUN --mount=type=cache,id=pnpm,target=/pnpm/store CYPRESS_INSTALL_BINARY=0 pnpm install --frozen-lockfile
RUN pnpm build && rm -rf .next/cache

FROM ${NODE_IMAGE}
ARG COMMIT_TAG
ENV NODE_ENV=production
ENV COMMIT_TAG=${COMMIT_TAG}
RUN apk add --no-cache tzdata
USER node:node
WORKDIR /app
COPY --chown=node:node --from=base /app ./
COPY --chown=node:node --from=prod-deps /app/node_modules ./node_modules
COPY --chown=node:node --from=build /app/.next ./.next
COPY --chown=node:node --from=build /app/dist ./dist
RUN touch config/DOCKER && echo "{\"commitTag\": \"${COMMIT_TAG}\"}" > committag.json
EXPOSE 5055
CMD [ "npm", "start" ]
