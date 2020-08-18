import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:presentation_displays/display.dart';

const _listDisplay = "listDisplay";
const _showPresentation = "showPresentation";
const _transferDataToPresentation = "transferDataToPresentation";

const String DISPLAY_CATEGORY_PRESENTATION =
    "android.hardware.display.category.PRESENTATION";

class DisplayController extends ChangeNotifier {
  final _receiverChannel = "presentation_displays_plugin_0_engine";
  final _senderChannel = "presentation_displays_plugin";

  var _viewId = 0;
  MethodChannel _senderMethodChannel;
  MethodChannel _receiverMethodChannel;

  /// Callback to invoke after the platform view has been created.
  /// May be null.
  _onPlatformViewCreated(int viewId) {
    if (_viewId != viewId || _senderMethodChannel == null) {
      debugPrint('--------->: channel ${_senderChannel}_$viewId');
      _senderMethodChannel = MethodChannel("${_senderChannel}_$viewId");
      _senderMethodChannel.setMethodCallHandler((call) async {
        debugPrint('--------->: method: ${call.method} | arguments: ${call.arguments}');
      });
    }
  }

  /// Gets all currently valid logical displays of the specified category.
  /// <p>
  /// When there are multiple displays in a category the returned displays are sorted
  /// of preference.  For example, if the requested category is
  /// {@link [DISPLAY_CATEGORY_PRESENTATION]} and there are multiple presentation displays
  /// then the displays are sorted so that the first display in the returned array
  /// is the most preferred presentation display.  The application may simply
  /// use the first display or allow the user to choose.
  /// </p>
  ///
  /// [category] The requested display category or null to return all displays.
  /// @return An array containing all displays sorted by order of preference.
  ///
  /// @see [DISPLAY_CATEGORY_PRESENTATION]
  FutureOr<List<Display>> getDisplays({String category}) async {
    List<dynamic> origins = await jsonDecode(
            await _senderMethodChannel?.invokeMethod(_listDisplay, category)) ??
        [];
    List<Display> displays = [];
    origins.forEach((element) {
      Map map = jsonDecode(jsonEncode(element));
      displays.add(displayFromJson(map));
    });
    return displays;
  }

  /// Gets the name of the display by [displayId] of [getDisplays].
  /// <p>
  /// Note that some displays may be renamed by the user.
  /// [category] The requested display category or null to return all displays.
  /// @see [DISPLAY_CATEGORY_PRESENTATION]
  /// </p>
  ///
  /// @return The display's name.
  /// May be null.
  FutureOr<String> getNameByDisplayId(int displayId, {String category}) async {
    List<Display> displays = await getDisplays(category: category) ?? [];

    String name;
    displays.forEach((element) {
      if (element.displayId == displayId) name = element.name;
    });
    return name;
  }

  /// Gets the name of the display by [index] of [getDisplays].
  /// <p>
  /// Note that some displays may be renamed by the user.
  /// [category] The requested display category or null to return all displays.
  /// @see [DISPLAY_CATEGORY_PRESENTATION]
  /// </p>
  ///
  /// @return The display's name
  /// May be null.
  FutureOr<String> getNameByIndex(int index, {String category}) async {
    List<Display> displays = await getDisplays(category: category) ?? [];
    String name;
    if (index >= 0 && index <= displays.length) name = displays[index].name;
    return name;
  }

  /// Creates a new presentation that is attached to the specified display
  /// using the default theme.
  /// <p>
  /// Before displaying a Presentation display, please define the UI you want to display in the [Route].
  /// If we can't find the router name, the presentation displays a blank screen
  /// [displayId] The id of display to which the presentation should be attached.
  /// [routerName] The screen you want to display on the presentation.
  /// </P>
  ///
  /// @return [Future<bool>] about the status has been display or not
  Future<bool> showPresentation(int displayId, String routerName) {
    return _senderMethodChannel?.invokeMethod(_showPresentation, "{"
        "\"displayId\": $displayId,"
        "\"routerName\": \"$routerName\""
        "}");
  }

  /// Transfer data to Presentation display
  /// <p>
  /// Transfer data from main screen to screen Presentation display
  /// Consider using [arguments] for cases where a particular run-time type is expected. Consider using String when that run-time type is Map or JSONObject.
  /// </p>
  ///
  /// @return [Future<bool>] the value to determine whether or not the data has been transferred successfully
  Future<bool> transferDataToPresentation(dynamic arguments) {
    return _senderMethodChannel?.invokeMethod(
        _transferDataToPresentation, arguments);
  }

  /// Only use a subscription to listen within the presentation display
  /// <p>
  /// Sets a callback for receiving method calls on this [addListenerForPresentation].
  /// The given callback will replace the currently registered callback for this
  /// [addListenerForPresentation], if any.
  ///
  /// If the future returned by the handler completes with a result
  /// </p>
  addListenerForPresentation(Function function) {
    _receiverMethodChannel = MethodChannel(_receiverChannel);
    _receiverMethodChannel.setMethodCallHandler((call) async {
      debugPrint('--------->: method: ${call.method} | arguments: ${call.arguments}');
      function(call.arguments);
    });
  }
}

/// Please wrap this theme on your Widget, it will provide you with the [DisplayController] method for you to work with PresentationDisplay.
class PresentationDisplays extends StatefulWidget {
  PresentationDisplays({@required this.controller,this.child});

  final DisplayController controller;
  final Widget child;

  @override
  _PresentationDisplaysState createState() => _PresentationDisplaysState();
}

class _PresentationDisplaysState extends State<PresentationDisplays> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AndroidView(
          viewType: widget.controller._senderChannel,
          onPlatformViewCreated: (viewId) =>
              widget.controller._onPlatformViewCreated(viewId),
        ),
        widget.child
      ],
    );
  }
}
