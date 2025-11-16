# Security Policy

English | [简体中文](Docs/SECURITY.zh-CN.md)

---

## Supported Versions

We release security updates for the following versions of Minecraft Launcher:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < Latest| :x:                |

**Note**: This project is currently in active development. We recommend always using the latest version from the main branch to ensure you have the most recent security patches.

---

## Reporting a Vulnerability

We take the security of Minecraft Launcher seriously. If you discover a security vulnerability, please help us protect our users by reporting it responsibly.

### How to Report

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by:

1. **Opening a private security advisory** on GitHub:
   - Go to the [Security Advisories](https://github.com/LemniAnvil/Launcher/security/advisories) page
   - Click "Report a vulnerability"
   - Fill in the details of the vulnerability

2. **Contacting the maintainers directly** through:
   - Opening a private issue (if available)
   - Contacting via the contact information provided in the project

### What to Include

When reporting a vulnerability, please include:

- **Description**: A clear description of the vulnerability
- **Impact**: The potential impact and severity of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the vulnerability
- **Proof of Concept**: If possible, include a proof of concept or exploit code
- **Affected Versions**: Which versions of the launcher are affected
- **Suggested Fix**: If you have suggestions for fixing the issue

### Response Timeline

- **Initial Response**: We aim to acknowledge receipt of your vulnerability report within 48 hours
- **Status Updates**: We will provide regular updates on the progress of addressing the vulnerability
- **Resolution**: We will work to resolve critical vulnerabilities as quickly as possible, typically within 7-14 days for critical issues

### Disclosure Policy

- We follow a **coordinated disclosure** approach
- We request that you do not publicly disclose the vulnerability until we have released a fix
- Once a fix is released, we will credit you (if desired) in the security advisory and release notes
- We aim to release security fixes within 90 days of the initial report

---

## Security Considerations

### Account Security

This launcher supports Microsoft account authentication for Minecraft. Please note:

- **Never share your account credentials** with anyone
- **Use strong, unique passwords** for your Microsoft account
- **Enable two-factor authentication** on your Microsoft account
- The launcher **never stores your password** - only authentication tokens
- Authentication tokens are stored securely in the macOS Keychain

### Download Security

The launcher downloads game files from official Mojang/Microsoft servers:

- All downloads are verified using **SHA1 checksums**
- Files are downloaded over **HTTPS** connections
- The launcher verifies file integrity before installation
- Only official Mojang/Microsoft servers are used for game downloads

### Proxy Security

If you use proxy settings:

- Be cautious when using third-party proxies
- Only use proxies from trusted sources
- Proxy credentials (if any) are stored securely
- SOCKS5 proxies provide better security than HTTP proxies

### File System Security

The launcher operates within standard Minecraft directories:

- Default location: `~/.minecraft/`
- The launcher only accesses files within this directory and its subdirectories
- No system files are modified outside the Minecraft directory
- All file operations are logged for transparency

### Network Security

- All connections to Mojang/Microsoft servers use **HTTPS**
- Certificate validation is enforced
- The launcher does not make connections to unauthorized third-party servers
- Network requests are logged for debugging purposes

---

## Known Security Limitations

### Current Development Status

This project is in active development. Please be aware of the following:

1. **Beta Software**: This launcher is not yet production-ready
2. **Limited Testing**: Security testing is ongoing
3. **Rapid Changes**: The codebase is evolving quickly
4. **Proprietary UI Library**: Some components use a closed-source UI library

### Recommendations

- **Use at your own risk** during the development phase
- **Keep backups** of your Minecraft data
- **Monitor the repository** for security updates
- **Report any suspicious behavior** immediately

---

## Security Best Practices for Users

### General Guidelines

1. **Keep the launcher updated** to the latest version
2. **Download only from official sources** (GitHub releases)
3. **Verify the integrity** of downloaded releases
4. **Review permissions** requested by the launcher
5. **Use a dedicated Minecraft directory** if concerned about file access

### Account Safety

1. **Never enter credentials** in unofficial launchers or websites
2. **Use Microsoft's official authentication** flow
3. **Log out** when not using the launcher
4. **Revoke access** if you suspect unauthorized use

### System Security

1. **Keep macOS updated** to the latest version
2. **Use macOS security features** (Gatekeeper, XProtect)
3. **Run antivirus software** if desired
4. **Monitor system logs** for unusual activity

---

## Security Features

### Implemented Security Measures

-  **HTTPS-only connections** for all network requests
-  **SHA1 checksum verification** for all downloads
-  **Secure token storage** using macOS Keychain
-  **Input validation** for user-provided data
-  **Comprehensive logging** for audit trails
-  **Proxy support** with secure configuration
-  **No password storage** - token-based authentication only

### Planned Security Enhancements

- = **Code signing** for macOS releases
- = **Notarization** for macOS distribution
- = **Sandboxing** for enhanced isolation
- = **Automatic updates** with signature verification
- = **Enhanced logging** with security event monitoring
- = **Penetration testing** before stable release

---

## Compliance and Standards

### Licensing

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**. All security fixes and improvements must be shared under the same license.

### Privacy

- The launcher does not collect or transmit personal data
- Authentication is handled directly by Microsoft
- No analytics or telemetry are collected
- All data remains on your local machine

### Third-Party Dependencies

We regularly review and update dependencies to address known vulnerabilities:

- Swift Package Manager dependencies are monitored
- Security advisories are reviewed promptly
- Updates are applied as soon as possible

---

## Security Acknowledgments

We would like to thank the following individuals for responsibly disclosing security vulnerabilities:

*No security reports have been received yet.*

---

## Contact

For security-related inquiries that are not vulnerabilities, you can:

- Open a regular GitHub issue
- Contact the maintainers through the repository

For security vulnerabilities, please follow the reporting process outlined above.

---

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Apple Platform Security](https://support.apple.com/guide/security/welcome/web)
- [Microsoft Account Security](https://account.microsoft.com/security)
- [Minecraft Account Security](https://help.minecraft.net/hc/en-us/articles/4403181904525)

---

<div align="center">

**Thank you for helping keep Minecraft Launcher and our users safe!**

[ Back to Top](#security-policy)

</div>
