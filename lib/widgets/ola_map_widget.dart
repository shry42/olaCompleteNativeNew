import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OlaMapWidget extends StatefulWidget {
  final String apiKey;
  final Function(String)? onMapReady;
  final Function(String)? onMapError;
  
  const OlaMapWidget({
    Key? key,
    required this.apiKey,
    this.onMapReady,
    this.onMapError,
  }) : super(key: key);

  @override
  State<OlaMapWidget> createState() => _OlaMapWidgetState();
}

class _OlaMapWidgetState extends State<OlaMapWidget> {
  static const MethodChannel _channel = MethodChannel('ola_maps_channel');

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMapReady':
        widget.onMapReady?.call('Map is ready');
        break;
      case 'onMapError':
        widget.onMapError?.call(call.arguments.toString());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'ola_map_view',
      creationParams: {
        'apiKey': widget.apiKey,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}