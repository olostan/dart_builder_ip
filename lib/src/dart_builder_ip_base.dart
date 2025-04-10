import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';
import 'dart:io';

class BuilderIP extends Generator {
  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    var ip = "localhost";

    // Get all network interfaces
    var interfaces = await NetworkInterface.list(includeLinkLocal: true);

    // First try to find an address starting with 192.168
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        log.info(
            "Checking ${addr.address} (${addr.type.name}) on ${interface.name}");
        if (addr.type.name == 'IPv4' && addr.address.startsWith('192.168')) {
          ip = addr.address;
          break;
        }
      }
      if (ip != "localhost") break;
    }

    // If no 192.168.* address found, try for any valid local network IP
    if (ip == "localhost") {
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type.name == 'IPv4' &&
              (addr.address.startsWith('192.168') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            ip = addr.address;
            break;
          }
        }
        if (ip != "localhost") break;
      }
    }

    if (ip == "localhost") {
      log.warning(
          "Can't find suitable IPv4 local IP. Using localhost, so debugging on physical devices will not work.");
    }

    return '''
// Source library: ${library.element.source.uri}
part of "${library.element.source.shortName}";
const builderIp = '$ip';
''';
  }
}

Builder builderIPBuilder(BuilderOptions options) => LibraryBuilder(
      BuilderIP(),
      generatedExtension: '.builder-ip.dart',
    );
