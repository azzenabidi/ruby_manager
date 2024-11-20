
# Ruby Manager

A simple Ruby version manager written in Ruby. This tool helps you manage multiple Ruby versions by allowing you to install, uninstall, switch, and upgrade Ruby versions. It also ensures system dependencies are resolved automatically.

---

## Features

- Install specific Ruby versions from the official Ruby source.
- Switch between installed Ruby versions.
- Uninstall unwanted Ruby versions.
- Upgrade to the latest available Ruby version.
- `.ruby-version` file support for project-level Ruby management.
- Automatic resolution of system dependencies.
- Logging of operations for debugging purposes.
- Shims for Ruby executables to ensure proper isolation.

---

## Installation

1. Clone the repository or download the `ruby_manager.rb` script:
   ```bash
   git clone https://github.com/yourusername/ruby_manager
   cd ruby_manager
   ```

2. Make the script executable:
   ```bash
   chmod +x ruby_manager.rb
   ```

3. Ensure Ruby is installed on your system.

4. Install system dependencies (if not already installed):
   ```bash
   # On Debian/Ubuntu
   sudo apt-get update
   sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev

   # On macOS
   xcode-select --install
   brew install openssl readline zlib sqlite3
   ```

---

## Usage

Run the script using the following commands:

### Install a Ruby Version
```bash
./ruby_manager.rb --install <version>
```
Example:
```bash
./ruby_manager.rb --install 3.2.0
```

### List Installed Ruby Versions
```bash
./ruby_manager.rb --list
```

### Switch to a Specific Ruby Version
```bash
./ruby_manager.rb --switch <version>
```
Example:
```bash
./ruby_manager.rb --switch 3.2.0
```

### Uninstall a Ruby Version
```bash
./ruby_manager.rb --uninstall <version>
```
Example:
```bash
./ruby_manager.rb --uninstall 3.1.0
```

### Upgrade to the Latest Ruby Version
```bash
./ruby_manager.rb --upgrade
```

### Update the Ruby Manager Script
```bash
./ruby_manager.rb --update-manager
```

### Use `.ruby-version` File
Automatically switch to the Ruby version specified in the `.ruby-version` file:
```bash
./ruby_manager.rb --switch-to-version-file
```

---

## Configuration

The Ruby Manager uses a configuration file located at `~/.myruby/config.yml`. By default, it uses:
- `~/.myruby/versions` for Ruby installations.
- `~/.myruby/shims` for executable shims.

You can edit the `config.yml` file to customize these paths.

---

## Logging

Operations are logged in `~/.myruby/logs/manager.log`. Check this file for debugging information.

---

## Troubleshooting

### Missing Dependencies
Ensure all required dependencies are installed. Run:
```bash
sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev
```

### Gems Missing Native Extensions
Rebuild all installed gems with:
```bash
gem pristine --all
```

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

