<p align="center"><img src="src/icons/icon.svg" /></p>

# thinOS
![License](https://img.shields.io/github/license/LaswitchTech/thinOS?style=for-the-badge)
![GitHub repo size](https://img.shields.io/github/repo-size/LaswitchTech/thinOS?style=for-the-badge&logo=github)
![GitHub top language](https://img.shields.io/github/languages/top/LaswitchTech/thinOS?style=for-the-badge)
![GitHub Downloads](https://img.shields.io/github/downloads/LaswitchTech/thinOS/total?style=for-the-badge)
![Version](https://img.shields.io/github/v/release/LaswitchTech/thinOS?label=Version&style=for-the-badge)

## Description
thinOS is a lightweight, cross-platform desktop operating system designed for efficiency and simplicity. It provides a minimalistic environment optimized for performance, making it ideal for users who require a fast and responsive system without unnecessary bloat. thinOS is built with modern technologies to ensure compatibility with a wide range of hardware while maintaining a sleek user interface.

## Features
  - **Lightweight Design**: thinOS is optimized for speed and efficiency, ensuring quick boot times and low resource consumption.
  - **Cross-Platform Compatibility**: Designed to run on various hardware architectures, thinOS supports a wide range of devices.
  - **User-Friendly Interface**: The operating system features a clean and intuitive user interface, making it easy for users to navigate and manage their system.
  - **Customizable Environment**: Users can tailor their thinOS experience with various themes, extensions, and configurations.
  - **Robust Security**: thinOS includes built-in security features to protect user data and maintain system integrity.

## Installation
To install thinOS, login to your current operating system (Debian based distributions supported only) and run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/LaswitchTech/thinOS/stable/setup.sh | bash
```

### On Debian
Install sudo and curl if not already installed:

```bash
su -
apt update
apt install sudo curl -y
usermod -aG sudo your_username
exit
```

Then run the installation command above.


### AMD GPU Acceleration
To enable AMD GPU acceleration, install the following packages before running the installation script:

```bash
sudo apt install firmware-amd-graphics -y
```

### NVIDIA GPU Acceleration
To enable NVIDIA GPU acceleration, install the following packages before running the installation script:

```bash
sudo apt install nvidia-detect -y
nvidia-detect
sudo apt install nvidia-driver -y # or the recommended driver from nvidia-detect
```

### Tested On
  - Debian 12 (Bookworm)
  - Raspberry Pi OS (Bookworm) (64-bit) Lite

## License
This software is distributed under the [GPLv3](LICENSE) license.

## Security
Please disclose any vulnerabilities found responsibly – report security issues to the maintainers privately. See [SECURITY.md](SECURITY.md) for more information.

## Contributing
Contributions to thinOS are welcome! If you have ideas for new features or have found bugs, please open an issue or submit a pull request.

### How to Contribute
  - **Fork the Repository**: Create a fork of the repository on GitHub.
  - **Create a New Branch**: For new features or bug fixes, create a new branch in your fork.
  - **Submit a Pull Request**: Once your changes are ready, submit a pull request to the main repository.

## To Do
  - **Remote Assitance**: Implement a remote assistance feature for user support.
  - **Provisioning System**: Develop a provisioning system for easier deployment and management.
  - **Splash Screen**: Add a customizable splash screen during boot.
  - **Screen Manager**: Integrate a screen manager for better multi-monitor support.

## Wait, where is the documentation?
Review the [Documentation](https://laswitchtech.com/en/blog/projects/thinos/index).
