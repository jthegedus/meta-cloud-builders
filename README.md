# Meta Cloud Builders

> Supercharge your Cloud Building with these custom Builders!

- `meta-cloud-builder`: Build community or custom Cloud Build Images (Builders)
  from a configuration file. !!!! could just grep the repo for cloud build files
  and diff against images in artifact registry to determine if images exist and
  if not build the corrent ones
  - Update the builder when new updates happen? Ratchet-like support for this?
    version tags (git tags) should exist, but perhaps SHA from git updates
    should also be supported?
- `trigger-sync`: Deploy your Cloud Build Triggers from configuration files.
  Supports `yaml` & `json`.

### TODO

- create a `github.com/jthegedus/cloud-builders-community` repo to capture other
  builders. EG:
  - `github-repository-settings`: configuration for repository settings via
    config file in repo
  - `cloud-build-dependabot`: Automatically PR updates to Builders used in Cloud
    Build configuration files.
    - compatible with `cloud-build-lint` ratchet requirements (have separate
      ratchet builder?)
  - `cloud-build-lint`: Lint your Cloud Build configuration files.
    - similar to https://github.com/sethvargo/ratchet
    - enforce best-practices for container images
      - SHA
      - TAG
      - explicit `latest` as opposed to the suggested implicit of current docs.
    - use `shfmt`, `shellcheck`, etc for inline scripts?

## License

[MIT License](https://github.com/jthegedus/meta-cloud-builder/blob/master/LICENSE)
