# Helm Boilerplate Template

This directory is a [Boilerplate](https://github.com/gruntwork-io/boilerplate) template for generating a Helm chart in the repository root.

## Render the template

```bash
boilerplate --template-url scaffolds/helm --output-folder . --non-interactive
```

The template provides local Helm defaults through `boilerplate.yml`, so the rendered chart is valid without extra input.

## Validate the rendered chart

```bash
helm lint .
helm template test-release .
```
