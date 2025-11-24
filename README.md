# DNS Changer

A fully functional Windows desktop application built with Flutter for changing DNS settings. This app allows users to easily switch between popular DNS providers or restore to default settings.

## Features

- **DNS Provider Selection**: Choose from a curated list of popular DNS providers including Cloudflare, Google Public DNS, Quad9, CleanBrowsing, and DNS.SB.
- **Automatic Adapter Detection**: Automatically detects available network adapters on your Windows system.
- **IPv4 and IPv6 Support**: Supports both IPv4 and IPv6 DNS configurations.
- **Restore to Default**: Easily restore DNS settings to DHCP (default) configuration.
- **Real-time Status**: View current DNS configuration for the selected adapter.
- **DNS Cache Flush**: Automatically flushes DNS cache after changes to ensure immediate effect.
- **Modern UI**: Clean, intuitive interface with Material Design 3 and support for light/dark themes.
- **Logging**: Comprehensive logging for troubleshooting and monitoring.
- **Extensible Architecture**: Built with MVVM pattern for easy addition of new features and providers.
- **DPI Bypass**: Advanced feature with multiple bypass modes using bundled GoodbyeDPI executable.
- **Unblock Websites**: Combined DNS + DPI bypass provides maximum website unblocking capability.

## Supported DNS Providers

Choose a DNS provider based on your needs. For maximum unblocking and privacy:

- **Cloudflare (1.1.1.1)**: Fast, reliable DNS with no-logging policy. Recommended for unblocking.
- **DNS.SB**: Fast, stable, and uncensored DNS resolver. Good for privacy.
- **Google Public DNS (8.8.8.8)**: Enhanced security and performance.

For content filtering (may block some sites):

- **Quad9**: Blocks malicious domains with threat intelligence.
- **CleanBrowsing**: Family-friendly DNS with content filtering.

## DPI Bypass Modes

The app includes multiple DPI bypass modes powered by GoodbyeDPI, based on real-world tested configurations:

- **Basic Bypass**: Simple bypass mode for most websites (`-1`)
- **Standard Bypass**: Standard bypass with fake packet generation (`-1 --fake-gen=1`)
- **Advanced Bypass**: Advanced bypass with custom fake packets
- **Russia Blacklist**: Bypass with Russia-specific blacklist (`-9 --blacklist`)
- **Russia DNS Redirect**: Russia bypass with DNS redirection and custom ports
- **Universal Bypass**: Universal bypass for any country blocking (`-9`)
- **YouTube Focus**: Optimized for YouTube unblocking with YouTube-specific blacklist

Select the appropriate mode based on your ISP's blocking method and geographic location.

## How to Use

1. **Launch the App**: Run the DNS Changer application on your Windows machine.
2. **Select Network Adapter**: Choose the network adapter you want to configure from the dropdown menu.
3. **View Current DNS**: The app displays the current DNS settings for the selected adapter.
4. **Choose DNS Provider**: Browse the list of available DNS providers and select one that suits your needs.
5. **Apply Changes**: Click the "Apply" button next to your chosen provider to change the DNS settings.
6. **DPI Bypass (Advanced)**: Select a DPI bypass mode from the dropdown and click "Start DPI Bypass" for maximum unblocking capability. GoodbyeDPI is bundled with the app.
7. **Restore if Needed**: Use the "Restore to Default" button to revert to your ISP's default DNS settings.

## Requirements

- Windows 10 or later
- Administrator privileges (run the app as administrator)
- Microsoft Visual C++ Redistributable (latest version) - download from Microsoft if you encounter startup errors

## Installation

1. Ensure you have Flutter installed and configured for Windows desktop development.
2. Clone this repository.
3. Run `flutter pub get` to install dependencies.
4. Build the app: `flutter build windows`
5. Run the app: `flutter run -d windows`

## Architecture

The app follows a clean architecture pattern with separation of concerns:

- **Presentation Layer**: UI components and view models using Provider for state management.
- **Domain Layer**: Business logic encapsulated in use cases.
- **Data Layer**: Repositories and services for data handling and external interactions.

This architecture makes the app highly maintainable and extensible.

## Logging

The app uses structured logging to record all operations. Logs are output to the console and can be viewed in development tools. Key events logged include:

- DNS changes
- Adapter selections
- Errors and exceptions

## Security Note

Changing DNS settings requires administrator privileges. The app uses Windows `netsh` commands to modify network settings. Ensure you trust the source of any DNS provider you choose, as DNS can affect your internet security and privacy.

## Troubleshooting

### Websites Still Blocked After DNS Change

If some websites remain blocked after changing DNS:

1. **Wait a moment**: DNS changes may take 1-2 minutes to fully propagate.
2. **Check DNS provider**: Some providers (like Quad9 or CleanBrowsing) intentionally block certain content. Use Cloudflare or Google for maximum unblocking.
3. **Flush DNS cache**: The app automatically flushes the cache, but you can manually run `ipconfig /flushdns` in Command Prompt.
4. **Restart browser**: Clear browser cache and restart.
5. **Check firewall**: If sites are blocked by Windows Firewall or other security software, DNS change won't help.
6. **ISP blocking**: Some ISPs block sites at the network level. VPN or proxy may be needed for complete unblocking.

### DNS Change Fails

- Ensure you're running the app as Administrator
- Check that the network adapter is selected correctly
- Verify internet connection is active

## Contributing

To add more DNS providers or features:

1. Update the `DnsProviderRepository` with new provider data.
2. Ensure the data follows the `DnsProvider` model structure.
3. Test thoroughly on Windows systems.

## License

This project is open-source. Please refer to the license file for details.
