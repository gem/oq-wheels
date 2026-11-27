# oq-wheels

Those distributions, or "wheels", include GDAL, Fiona, pyproj, geopandas and pyogrio
## Release & Tagging Workflow

0. **Fork the official repository** into the `gem` organization/namespace and clone it locally.

1. **Create a new branch** starting from the original upstream tag:
   ```bash
   git checkout -b v0.13.0_gem v0.13.0
   ```

2. **Make your changes** and commit them:
   ```bash
   git add .
   git commit -m "Your commit message"
   ```

3. **Update the version** according to the repository type:
   - **GDAL:** Update the `VERSION` file located in the repository root.
   - **Other repositories:** Update the version inside the `__init__.py` file.

   > **Important (`geopandas` and `pyogrio`):** While tagging is always required, for `geopandas` and `pyogrio` the version bump **must** be committed in a dedicated, standalone commit containing only that change, and the tag must be applied to that specific commit:
   > ```bash
   > # 1. Edit only the version file (e.g., __init__.py)
   > git add <version_file>
   > git commit -m "Bump version to v0.13.0+gemYYMMDD"
   >
   > # 2. Create the tag on this dedicated commit and push
   > git tag v0.13.0+gemYYMMDD
   > git push -u origin v0.13.0_gem
   > git push origin --tags
   > ```

4. **Create a new tag** appending `+gemYYMMDD` (e.g., `v0.13.0+gem261127`):
   ```bash
   git tag v0.13.0+gemYYMMDD
   ```

5. **Push the branch and tags** to the remote repository:
   ```bash
   git push -u origin v0.13.0_gem
   git push origin --tags
   ```
