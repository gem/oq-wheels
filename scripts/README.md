
---

# Downloading `.whl` Files Using `artifacts.bash`

If you want to download `.whl` files using the `artifacts.bash` script, make sure to follow these steps first:

1. **Install GitHub CLI (gh):**
   Before downloading the `.whl` files, you need to install the GitHub CLI (`gh`). Follow the installation instructions from the [GitHub CLI documentation](https://cli.github.com/).

2. **Authenticate with GitHub:**
   After installing `gh`, authenticate using your GitHub credentials:
   ```sh
   gh auth login
   ```

3. **Download `.whl` files using the script:**
   Once you are authenticated, you can use the `artifacts.bash` script to download the `.whl` files.
   ```sh
   ./download_artifacts.bash
   ```

# How to Find and Copy `.whl` Files Using `find`, `xargs`, and `scp`

If you want to find all `.whl` files in subdirectories and copy them to a remote destination using `find`, `xargs`, and `scp`, follow these steps:

```sh
find /path/to/search -type f -name "*.whl" -print0 | xargs -0 -I {} scp <option_of_scp> {} user@remote_host:/path/to/destination/
```

### Explanation:

- `/path/to/search`: Replace with the path where you want to search for `.whl` files.
- `user@remote_host`: Replace with the username and hostname of the remote server where you want to copy the files.
- `/path/to/destination/`: Replace with the destination path on the remote server.

---
