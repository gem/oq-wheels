# oq-wheels

Those distributions, or "wheels", include GDAL, Fiona, pyproj, geopandas and pyogrio

## Release & Tagging Workflow

1. **Create a new branch** starting from the original upstream tag:
   ```bash
   git checkout -b v0.13.0_gem v0.13.0
   ```

2. **Make your changes** and commit them:
   ```bash
   git add .
   git commit -m "Your commit message"
   ```
   > **Note for GDAL:** Update the `VERSION` file located in the repository root before committing.

3. **Create a new tag** appending `+gemYYMMDD` (e.g., `v0.13.0+gem261127`):
   ```bash
   git tag v0.13.0+gemYYMMDD
   ```

4. **Push the branch and tags** to the remote repository:
   ```bash
   git push -u origin v0.13.0_gem
   git push origin --tags
   ```
