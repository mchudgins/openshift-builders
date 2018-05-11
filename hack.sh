#!/usr/bin/env bash

function createIS {
    tmpfile=`mktemp`

    cat <<EOF >${tmpfile}
apiVersion: v1
kind: ImageStream
metadata:
  labels:
    created-by: hack-script
    owner: ${USER}
  name: $1
spec:
    name: latest
EOF

    cat ${tmpfile} | oc create -f - && rm ${tmpfile}
}


function createBuildConfig {
    tmpfile=`mktemp`

    cat <<EOF >${tmpfile}
apiVersion: v1
kind: BuildConfig
metadata:
  annotations:
    openshift.io/git-repository: openshift-builders
  labels:
    created-by: hack-script
    owner: ${USER}
  name: s2i-golang
spec:
  failedBuildsHistoryLimit: 3
  successfulBuildsHistoryLimit: 3
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: s2i-golang:latest
  runPolicy: Serial
  source:
    contextDir: /s2i-go
    git:
      ref: golang
      uri: http://git/openshift-builders.git
    type: Git
  strategy:
    dockerStrategy:
      from:
        kind: ImageStreamTag
        name: golang:latest
    type: Docker
  triggers:
  - imageChange: {}
    type: ImageChange
  - type: Generic
    generic:
      secret: aSecretValue
EOF

oc create -f ${tmpfile} && rm ${tmpfile}
}

function createMonoRepoBuildConfig {
    tmpfile=`mktemp`

    cat <<EOF >${tmpfile}
apiVersion: v1
kind: BuildConfig
metadata:
  annotations:
    openshift.io/git-repository: go
  labels:
    created-by: hack-script
    owner: ${USER}
  name: go-monorepo
spec:
  failedBuildsHistoryLimit: 3
  successfulBuildsHistoryLimit: 3
  output:
    to:
      kind: ImageStreamTag
      name: go-monorepo:latest
  runPolicy: Serial
  source:
    contextDir: /
    git:
      ref: master
      uri: http://git/go.git
    type: Git
  strategy:
    sourceStrategy:
      env:
      - name: SOURCE_REPO_ORIGIN
        value: https://gitlab.com/dstcorp/go.git
#      - name: TARGET_PKG
#        value: gitlab.com/dstcorp/go/cmd/gitWebhookEndpoint
      from:
        kind: ImageStreamTag
        name: s2i-golang:latest
  triggers:
  - imageChange: {}
    type: ImageChange
  - type: Generic
    generic:
      secret: aSecretValue
EOF

oc create -f ${tmpfile} && rm ${tmpfile}
}

function createHackBuildConfig {
    tmpfile=`mktemp`
    name=$(echo $1 | tr '[:upper:]' '[:lower:]')

    cat <<EOF >${tmpfile}
apiVersion: v1
kind: BuildConfig
metadata:
  name: ${name}
  labels:
    created-by: hack-script
    owner: ${USER}
spec:
  output:
    to:
      kind: ImageStreamTag
      name: ${name}:latest
  source:
    dockerfile: |-
      FROM Scratch
       # listen port for the web app
      Expose 8443/tcp
       # listen port for the metrics
      Expose 9000/tcp
      COPY ./bin/$1 /$1
    images:
    - from:
        kind: ImageStreamTag
        name: go-monorepo:latest
      paths:
      - sourcePath: /go/bin
        destinationDir: "."
  strategy:
    dockerStrategy:
        from:
            kind: DockerImage
            name: scratch
  triggers:
  - imageChange:
    from:
        kind: ImageStreamTag
        name: go-monorepo:latest
    type: ImageChange
EOF

oc create -f ${tmpfile} && rm ${tmpfile}
}

#########################################
# main line of shell script starts here #
#########################################

# make sure we know what we're hacking
if [[ -z "$1" ]]; then
    echo "Usage:  $0 <hack>"
    echo
    cmds=`ls -d ${GOPATH}/src/gitlab.com/dstcorp/go/cmd/* 2>/dev/null`
    if [[ -z "${cmds}" ]]; then
        echo "$0 must be run from ${GOPATH}/src/gitlab.com/dstcorp/go subdirectory"
        exit 1
    fi
    echo "where <hack> is one of:"
    for i in ${cmds}; do
        echo "        $(basename $i)"
    done
    exit 1
fi

# check we're logged in and obtain current list of images
images=`oc get is --template '{{ range .items }} {{ .metadata.name }} {{ end }}'`
if [[ $? -ne 0 ]]; then
    echo "You must be logged into the Openshift cluster.  Server said: "
    echo ${images}
    exit $?
fi

hack=$(echo $1 | tr '[:upper:]' '[:lower:]')

# create the golang IS
ignore=`oc get is/golang 2>/dev/null`
if [[ $? -ne 0 ]]; then
    oc import-image golang --from=golang:1.10-alpine3.7 --confirm
fi

# create the s2i-golang IS
ignore=`oc get is/s2i-golang 2>/dev/null`
if [[ $? -ne 0 ]]; then
    createIS s2i-golang
fi

# create the go-monorepo IS
ignore=`oc get is/go-monorepo 2>/dev/null`
if [[ $? -ne 0 ]]; then
    createIS go-monorepo
fi

# create the go-monorepo IS
ignore=`oc get is/${hack} 2>/dev/null`
if [[ $? -ne 0 ]]; then
    createIS ${hack}
fi

# create the s2i-golang build config
ignore=`oc get bc/s2i-golang 2>/dev/null`
if [[ $? -ne 0 ]]; then
    createBuildConfig
fi

# create the mono repo build config
ignore=`oc get bc/go-monorepo 2>/dev/null`
if [[ $? -ne 0 ]]; then
    createMonoRepoBuildConfig
fi

# create the build config for hack output
ignore=`oc get bc/${hack} 2>/dev/null`
if [[ $? -ne 0 ]]; then
    createHackBuildConfig $1
fi

# finally, create the gitserver, if necessary
ignore=`oc get dc/git 2>/dev/null`
if [[ $? -ne 0 ]]; then
    tmpfile=`mktemp`

    # see https://github.com/openshift/origin/tree/master/examples/gitserver
    cat <<'EOF' >${tmpfile}
apiVersion: v1
kind: List
items:
- apiVersion: v1
  kind: DeploymentConfig
  metadata:
    name: git
    labels:
      app: git
  spec:
    strategy:
      type: Recreate
    replicas: 1 # the git server is not HA and should not be scaled past 1
    selector:
      run-container: git
    template:
      metadata:
        labels:
          run-container: git
      spec:
        serviceAccountName: git
        containers:
        - name: git
          image: openshift/origin-gitserver:latest
          ports:
          - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /_/healthz
              port: 8080

          env:
          # Each environment variable matching GIT_INITIAL_CLONE_* will
          # be cloned when the process starts; failures will be logged.
          # <name> must be [A-Z0-9_\-\.], the cloned directory name will
          # be lowercased. If the name is invalid the pod will halt. If
          # the repository already exists on disk, it will be updated
          # from the remote.
          #
          #- name: GIT_INITIAL_CLONE_1
          #  value:  <url>[;<name>]


          # The namespace of the pod is required for implicit config
          # (passing '-' to AUTOLINK_KUBECONFIG or REQUIRE_SERVER_AUTH)
          # and can also be used to target a specific namespace.
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace

          # The URL that builds must use to access the Git repositories
          # stored in this app.
          # TODO: support HTTPS
          - name: PUBLIC_URL
            value: http://git.$(POD_NAMESPACE).svc.cluster.local:8080
          # If INTERNAL_URL is specified, then it's used to point
          # BuildConfigs to the internal service address of the git
          # server
          - name: INTERNAL_URL
            value: http://git:8080

          # The directory to store Git repositories in. If not backed
          # by a persistent volume, repositories will be lost when
          # deployments occur. Use INITIAL_GIT_CLONE and AUTOLINK_*
          # to remove the need to use a persistent volume.
          - name: GIT_HOME
            value: /var/lib/git

          # The directory to use as the default hook directory for any
          # cloned or autolinked directories.
          - name: HOOK_PATH
            value: /var/lib/git-hooks

          # If 'true' new-app will be invoked on push for repositories
          # for which a matching BuildConfig is not found.
          - name: GENERATE_ARTIFACTS
            value: "true"

          # The strategy to use when creating build artifacts from a repository.
          # With the default empty value, a Docker build  will be generated if
          # a Dockerfile is present in the repository. Otherwise, a source build
          # will be created. Valid values are: "", docker, source
          - name: BUILD_STRATEGY
            value: ""

          # The script to use for custom language detection on a
          # repository. See hooks/detect-language for an example.
          # To use new-app's default detection, leave this variable
          # blank.
          - name: DETECTION_SCRIPT
          # value: detect-language

          # Authentication and authorization

          # If 'true', clients may push to the server with git push.
          - name: ALLOW_GIT_PUSH
            value: "true"
          # If 'true', clients may set hooks via the API. However, unless
          # the Git home is backed by a persistent volume, any deployment
          # will result in the hooks being lost.
          - name: ALLOW_GIT_HOOKS
            value: "true"
          # If 'true', clients can create new git repositories on demand
          # by pushing. If the data on disk is not backed by a persistent
          # volume, the Git repo will be deleted if the deployment is
          # updated.
          - name: ALLOW_LAZY_CREATE
            value: "true"
          # If 'true', clients can pull without being authenticated.
          - name: ALLOW_ANON_GIT_PULL
            value: "true"

          # Provides the path to a kubeconfig file in the image that
          # should be used to authorize against the server. The value
          # '-' will use the pod's service account.
          # May not be used in combination with REQUIRE_GIT_AUTH
          - name: REQUIRE_SERVER_AUTH
            value: "-"
          # The namespace to check authorization against when
          # REQUIRE_SERVICE_AUTH is used. Users must have 'get' on
          # 'pods' to pull and 'create' on 'pods' to push.
          - name: AUTH_NAMESPACE
            value: $(POD_NAMESPACE)
          # Require BASIC authentication with a username and password
          # to push or pull.
          # May not be used in combination with REQUIRE_SERVER_AUTH
          - name: REQUIRE_GIT_AUTH
          # value: <username>:<password>

          # Autolinking:
          #
          # The git server can automatically clone Git repositories
          # associated with a build config and replace the URL with
          # a link to the repo on PUBLIC_URL. The default post-receive
          # hook on the cloned repo will then trigger a build. You
          # may customize the hook with AUTOLINK_HOOK (path to hook).
          # To autolink, the account the pod runs under must have 'edit'
          # on the AUTOLINK_NAMESPACE:
          #
          #    oc policy add-role-to-user -z git edit
          #
          # Links are checked every time the pod starts.

          # The location to read auth configuration from for autolinking.
          # If '-', use the service account token to link. The account
          # represented by this config must have the edit role on the
          # namespace.
          - name: AUTOLINK_KUBECONFIG
            value: "-"

          # The namespace to autolink
          - name: AUTOLINK_NAMESPACE
            value: $(POD_NAMESPACE)
          # to push or pull.
          # May not be used in combination with REQUIRE_SERVER_AUTH
          - name: REQUIRE_GIT_AUTH
          # value: <username>:<password>

          # Autolinking:
          #
          # The git server can automatically clone Git repositories
          # associated with a build config and replace the URL with
          # a link to the repo on PUBLIC_URL. The default post-receive
          # hook on the cloned repo will then trigger a build. You
          # may customize the hook with AUTOLINK_HOOK (path to hook).
          # To autolink, the account the pod runs under must have 'edit'
          # on the AUTOLINK_NAMESPACE:
          #
          #    oc policy add-role-to-user -z git edit
          #
          # Links are checked every time the pod starts.

          # The location to read auth configuration from for autolinking.
          # If '-', use the service account token to link. The account
          # represented by this config must have the edit role on the
          # namespace.
          - name: AUTOLINK_KUBECONFIG
            value: "-"

          # The namespace to autolink
          - name: AUTOLINK_NAMESPACE
            value: $(POD_NAMESPACE)

          # The path to a script in the image to use as the default
          # post-receive hook - only set during link, so has no effect
          # on cloned repositories. See the "hooks" directory in the
          # image for examples.
          - name: AUTOLINK_HOOK

          volumeMounts:
          - mountPath: /var/lib/git/
            name: git
        volumes:
        - name: git
          emptyDir: {}
    triggers:
    - type: ConfigChange

# The git server service is required for DNS resolution
- apiVersion: v1
  kind: Service
  metadata:
    name: git
    labels:
      app: git
  spec:
    ports:
    - port: 80
      targetPort: 8080
    selector:
      run-container: git

# The service account for the git server must be granted the view role to
# automatically start builds, edit role to create objects and autolink
- apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: git
    labels:
      app: git

# Default route for git service
- apiVersion: v1
  kind: Route
  metadata:
    labels:
      app: git
    name: git
  spec:
    to:
      name: git
EOF
    oc create -f ${tmpfile} && rm ${tmpfile}
fi
