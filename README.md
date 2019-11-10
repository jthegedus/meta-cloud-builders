# Meta Cloud Builders

- [`meta-cloud-builder`](#meta-cloud-builder): Build custom Cloud Build images (builders) from a config file.
- [`meta-triggers`](#meta-triggers): Watch and deploy all your Cloud Build Triggers on Trigger config changes.
- [Test](#test)
- [License](#license)

## meta-cloud-builder

> Build custom Cloud Build images (builders) from a config file

Manually build this image into your project once.

```shell
# clone
git clone https://github.com/jthegedus/meta-cloud-builders
# build
gcloud builds submit --config jthegedus/meta-cloud-builders/meta-cloud-builder/cloudbuild.yaml jthegedus/meta-cloud-builders/meta-cloud-builder
# validate
gcloud container images list --filter meta-cloud-builder
```

Create a `.yaml` or `.json` file with repos and the cloud-builder you wish to build into your project:

```yaml
# .cicd/builders/custom-builders.yaml
- repo: https://github.com/jthegedus/meta-cloud-builder
  builders:
    - meta-cloud-builder
    - meta-triggers
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
tags:
  - cloud-builders
```

This builder then invokes `gcloud builds submit ...` for cloud-builders defined in the configuration file. You can pass any `gcloud builds submit` flags to the builder except the `--config` and `SOURCE` aspects. [See the flags here](https://cloud.google.com/sdk/gcloud/reference/builds/submit).

<details>
<summary>Automate building your builders with a Trigger</summary>

### Triggers

Now with [Cloud Build Triggers being created via `.yaml` config](https://cloud.google.com/blog/products/devops-sre/cloud-build-brings-advanced-cicd-capabilities-to-github) we can run this `builders.cloudbuild.yaml` whenever we make a change to this config file.

```yaml
# .cicd/triggers/builders.trigger.yaml
name: cloud-builders
description: Build custom Cloud Build builders into my gcr project on change
github:
  owner: <org/user_name>
  name: <repo_name>
  push:
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

### Schedule

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

</details>

## meta-triggers

> Watch and deploy all your Cloud Build Triggers on Trigger config changes.

Manually build this image into your project once.

```shell
# clone
git clone https://github.com/jthegedus/meta-cloud-builders
# build
gcloud builds submit --config jthegedus/meta-cloud-builders/meta-triggers/cloudbuild.yaml jthegedus/meta-cloud-builders/meta-triggers
# validate
gcloud container images list --filter meta-triggers
```

Use the builder by specifying the dir to recursively check and the file suffix to match (I suggest `*.trigger.{json,yaml}`):

```yaml
# .cicd/apply-triggers.cloudbuild.yaml
steps:
  - name: gcr.io/$PROJECT_ID/meta-cloud-builder
    id: "Watch for changes to all Cloud Build Triggers"
    waitFor:
      - "-"
    args:
      - "--dir=.cicd/"
      - "--suffix=*.trigger.{json,yaml}"
```

Now we want to run this Cloud Build Job any time a file in the `--dir` changes. So we setup this trigger once:

```yaml
# .cicd/triggers/meta-trigger.trigger.yaml
name: meta-trigger
description: "Trigger to apply Triggers on change"
github:
  owner: <org/user_name>
  name: <repo_name>
  push:
    branch: master
filename: .cicd/apply-triggers.cloudbuild.yaml
includedFiles:
  - .cicd/**
```

For security purposes, I would suggest only running this trigger on pushes to `master` so that changes must be approved before they are applied.

## Test

- meta-cloud-builder: run from the repo root dir to test:

```shell
gcloud builds submit ./meta-cloud-builder/test/ --config=./meta-cloud-builder/test/cloudbuild.yaml
```

- meta-triggers: run from the repo root dir to test:

```shell
gcloud builds submit ./meta-triggers/test/ --config=./meta-triggers/test/cloudbuild.yaml
```

## License

[MIT License](https://github.com/jthegedus/meta-cloud-builder/blob/master/LICENSE)
