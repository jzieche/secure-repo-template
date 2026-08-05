# Helm Scaffold

Copy these files into a new repository root when you want the repo to start as a Helm chart.

## After copying

```bash
helm lint .
helm template test-release .
```

## Customize

- Rename `example-app` to the real chart name before publishing.
- Update `image.repository` and `image.tag` for your app.
