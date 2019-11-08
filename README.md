# Meta Cloud Builders

- `meta-cloud-builder`: Build custom cloud build images (builders) from a config file.
- `meta-cloud-build-triggers`: Watch and deploy Cloud Build Triggers on Trigger (`yaml`) config changes.

# Todo

- [ ] Rewrite readme for multiple builders

---

This build step invokes `gcloud builds submit ...` for custom cloud-builders specified in a configuration file.

* [Setup](#setup)
* [Usage](#usage)
* [Triggers](#triggers)
* [Schedule](#schedule)

## Setup

Manually build this image into your project once. Similar to [`cloud-builders-community`](https://github.com/GoogleCloudPlatform/cloud-builders-community#build-the-build-step-from-source/).

```shell
# clone
git clone https://github.com/jthegedus/meta-cloud-builder
# build
gcloud builds submit --config jthegedus/meta-cloud-builder/cloudbuild.yaml jthegedus/meta-cloud-builder
# validate
gcloud container images list --filter meta-cloud-builder
```

## Usage

Create a `.yaml` or `.json` file with key-value-pairs for the repo and cloud-builder you wish to build into your project:

```yaml
# .cicd/builders/custom-builders.yaml
- repo: https://github.com/jthegedus/meta-cloud-builder
  builders:
    - meta-cloud-builder
- repo: https://github.com/GoogleCloudPlatform/cloud-builders-community
  builders:
    - cancelot
    - cache
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
      - "--async"
      # other gcloud builds submit flags
tags:
  - cloud-builders
```

You can pass any `gcloud builds submit` flags to the builder except the `--config` and `DIR` aspects.

I would recommend passing the `--async` flag to create each builder concurrently.

## Triggers

Now with [Cloud Build Triggers being created via `.yaml` config](https://cloud.google.com/blog/products/devops-sre/cloud-build-brings-advanced-cicd-capabilities-to-github) we can run this `builders.cloudbuild.yaml` whenever we make a change to this config file.

```yaml
# .cicd/triggers/builders.trigger.yaml
name: cloud-builders
description: Build custom Cloud Build builders into my gcr project on change
github:
  owner: <org/user name>
  name: <repo name>
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

## Schedule

WIP: the message-body might need changing to run a GitHub-based Trigger - see this [Cloud Build Issue](https://issuetracker.google.com/issues/142550612).

With custom Cloud Builders you are almost always going to want the latest images from the source. Since we cannot trigger off of changes to external repos, we can at least rebuild these containers on a regular basis, say daily or weekly.

```shell
gcloud scheduler jobs create http \
  build-custom-cloud-builders \
  --description="Build custom cloud-builders on a schedule" \
  --schedule="0 0 * * SUN" \
  --time-zone="AEST"
  --http-method="POST" \
  --uri=https://cloudbuild.googleapis.com/v1/projects/[PROJECTID]/triggers/[TRIGGERID]:run \
  --message-body={"branchName": "master"} \
  --oauth-service-account-email=[EMAIL_ADDRESS]@appspot.gserviceaccount.com
```

Just fill in `PROJECTID`, `TRIGGERID` and create a Service Account and fill in the `EMAIL_ADDRESS` accordingly.

Suggested schedule intervals:
- daily: `0 0 * * *`
- every sunday: `0 0 * * SUN`

## Test

Run this script from the repo root dir to test the meta-cloud-builder:

```shell
gcloud builds submit ./meta-cloud-builder/test/ --config=./meta-cloud-builder/test/cloudbuild.yaml
```

## License

[MIT License](https://github.com/jthegedus/meta-cloud-builder/blob/master/LICENSE)
