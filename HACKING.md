# Hacking on Openshift

## Building a Build Config Image

This repository provides Openshift "Build Config" templates and images which
can be used to compile application source code and deploy it as a container image.

The 'generic-template.json' creates an Image Stream using a Docker Build Strategy.

A successful workflow for hacking on Image Streams created using the generic-template is:

1. Create a new project.

2. Deploy to your project an ephemeral git server.  This server will be used to store work-in-progress commits
which will later be squashed into a single commit.  Use the Openshift provided [template](https://github.com/openshift/origin/blob/master/examples/gitserver/gitserver-ephemeral.yaml).

3. Following the instructions, [clone](https://github.com/openshift/origin/tree/master/examples/gitserver)
this repository to a local subdirectory, configure the required openshift credentials, and push the repository to the ephemeral server.  It helps with automating the
"start build" process if the repository name and the build config name are the same; otherwise, follow the [instructions](https://github.com/openshift/origin/blob/master/examples/gitserver/gitserver-ephemeral.yaml) and add a build config annotation.
Additionally, ensure that the ephemeral git service account is able to start builds in openshift: `oc adm policy add-role-to-user admin -z git`

4. Create a local branch (which will later be merged into master). `git create -b test_branch`

5. Install the generic-template.json as a template in your project:  `oc install -f generic-template.json`

6. Using the web console, 'cause the cli is busted, create a build config for your new builder image.

7. Hack on the local Dockerfiles in your repo.  Commit changes as desired and push them to the ephemeral git server.

8. When satisfied, `git co master` and then `git merge --squash test_branch`, followed by git commit -m "Awesome commit message".

9. `git push origin master` and you are done.


