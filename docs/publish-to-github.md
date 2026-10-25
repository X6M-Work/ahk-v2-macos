# Publish the source

Create an empty GitHub repository named `ahk-v2-macos`. Keep the upstream credits and license.

From an extracted source archive:

```sh
git init -b main
git add .
git commit -m "Add Keysharp-based macOS distribution and compatibility workbench"
git remote add origin https://github.com/X6M-Work/ahk-v2-macos.git
git push -u origin main
```

From the supplied Git checkout, omit `git init`; it already has branch `main` and an `upstream` remote. Add your own `origin` with the command above.

The compatibility workflow runs after the push. Inspect both macOS architectures, the official Windows reference and the uploaded reports. The manual package workflow uploads unsigned packages as Actions artifacts; it does not create a release.

Suggested repository description:

> Experimental AutoHotkey v2 runtime for macOS, based on Keysharp.

Publish compatibility claims only for the cases and platforms actually tested. The project has not achieved 100% compatibility.
