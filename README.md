# Meta Cloud Builder

> Build custom builders from a config file.

This build step invokes `gcloud builds submit ...` for custom cloud-builders specified in a configuration file.

## Setup

Manually build this image into your project once. Similar to [`cloud-builders-community`](https://github.com/GoogleCloudPlatform/cloud-builders-community#build-the-build-step-from-source/).

```shell
# clone
git clone https://github.com/jthegedus/meta-cloud-builder
cd jthegedus/meta-cloud-builder
# build
gcloud builds submit --config cloudbuild.yaml .
# validate
gcloud container images list --filter meta-cloud-builder
```

## Usage

Create a `.yaml` or `.json` file with key-value-pairs for the repo and cloud-builder you wish to build into your project:

```yaml
# .cicd/builders/custom-builders.yaml
- name: meta-cloud-builder
  repo: https://github.com/jthegedus/meta-cloud-builder
- name: cancelot
  repo: https://github.com/Go ogleCloudPlatform/cloud-builders-community
- name: cache
  repo: https://github.com/Go ogleCloudPlatform/cloud-builders-community
```

then pass this config file into the `meta-cloud-builder` step as an arg:

```yaml
# .cicd/builders.cloudbuild.yaml
steps:
  - name: gcr.io/$PROJECT_ID/meta-cloud-builder
    id: "build custom cloud build builder(s) from a config file"
    waitFor:
      - "-"
    args:
      - ".cicd/builders/custom-builders.yaml"
tags:
  - cloud-builders
```

## Triggers

Now with [Cloud Build Triggers being created via `.yaml` config](https://cloud.google.com/blog/products/devops-sre/cloud-build-brings-advanced-cicd-capabilities-to-github) we can run this `builders.cloudbuild.yaml` whenever we make a change to this config file.

```yaml
# .cicd/triggers/builders.trigger.yaml
descrtiption: Build custom Cloud Build builders into my gcr project on change
github:
  owner: <org/user name>
  repo: <repo name>
  branch:
    branch: master
filename: .cicd/builders.cloudbuild.yaml
includedFiles:
  - .cicd/builders.cloudbuild.yaml      # the build file
  - .cicd/builders/custom-builders.yaml # the config file
```

Import the Trigger:

```shell
gcloud beta builds triggers import --source=.cicd/triggers/builders.trigger.yaml
```

## License

[MIT License](https://github.com/jthegedus/meta-cloud-builder/blob/master/LICENSE)
