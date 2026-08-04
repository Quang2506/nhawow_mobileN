import 'api_transport.dart';
import 'api_transport_stub.dart'
    if (dart.library.html) 'api_transport_web.dart'
    if (dart.library.io) 'api_transport_io.dart' as implementation;

ApiTransport createApiTransport() => implementation.createApiTransport();
