# Zen Browser Nix Flake

A Nix flake for building and packaging the Zen Browser.

## Usage

### Development

To enter the development environment:

```bash
nix develop
```

### Building

To build the Zen Browser:

```bash
nix build
```

To run it directly:

```bash
nix run
```

## Automated Updates

This flake includes a GitHub Action workflow that automatically checks for new Zen Browser releases and updates the flake when a new version is available.

### Workflow Configuration

The workflow file is located at `.github/workflows/update-zen-browser.yml` and includes:

- **Schedule**: Runs daily at 3 AM UTC
- **Manual trigger**: Can be manually triggered via GitHub Actions UI
- **Auto PR**: Creates a pull request when a new version is found

### How It Works

1. **Version Check**: The workflow fetches the latest release from the [Zen Browser GitHub repository](https://github.com/zen-browser/desktop/releases)
2. **Comparison**: Compares it with the version currently in `flake.nix`
3. **Hash Computation**: If a new version is found, it computes the new tarball hash using `nix-prefetch-url`
4. **Update**: Updates `flake.nix` with the new version and hash
5. **Pull Request**: Creates a PR for manual review and verification

### Manual Update

To manually check for and update to a new version:

1. Go to the "Actions" tab in your GitHub repository
2. Select "Update Zen Browser" workflow
3. Click "Run workflow"

Or use the GitHub CLI:

```bash
gh workflow run update-zen-browser.yml
```

## Configuration

To customize the update schedule, edit `.github/workflows/update-zen-browser.yml`:

```yaml
on:
  schedule:
    - cron: '0 3 * * *'  # Modify this cron expression
```

See [crontab.guru](https://crontab.guru) for cron syntax help.

## Structure

- `flake.nix` - The main Nix flake configuration with the Zen Browser package
- `.github/workflows/update-zen-browser.yml` - GitHub Action for automated updates
- `zen.desktop` - Desktop entry file for application launcher integration

## Requirements

- Nix with flakes support
- Linux x86_64 system
- Required runtime libraries (automatically managed by Nix)

## Notes

- The flake uses `nixos-unstable` channel for the latest packages
- The build includes proper library wrapping and environment variable setup for Firefox/Mozilla applications
- Desktop integration includes application menu entry and icon
