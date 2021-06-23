
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:retroconfig/widgets/collection_view.dart';
import '../configs.dart';
import 'details.dart';
import '../localizations/localizations.dart';

class _DisplayRectClipper extends CustomClipper<Rect> {

  Offset center;
  double value;

  _DisplayRectClipper(this.center, this.value);

  @override
  Rect getClip(Size size) {
    double length = (center - Offset(0, size.height)).distance;
    return Rect.fromCircle(
        center: center,
        radius: length * value
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return !(oldClipper is _DisplayRectClipper) || (oldClipper as _DisplayRectClipper).value != value;
  }
}

class _RectClipper extends CustomClipper<Rect> {

  double value;

  _RectClipper(this.value);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height * this.value);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return !(oldClipper is _RectClipper) || (oldClipper as _RectClipper).value != value;
  }
}

class AnimatedExtend extends StatefulWidget {

  final Widget child;
  final bool display;
  final Curve curve;
  final Curve reverseCurve;
  final Duration duration;

  AnimatedExtend({
    Key key,
    @required this.child,
    this.display = false,
    this.curve = Curves.linear,
    this.reverseCurve = Curves.linear,
    this.duration = const Duration(milliseconds: 300)
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AnimatedExtendState();

}

class _AnimatedExtendState extends State<AnimatedExtend> with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  Animation<double> get animation => _animation;
  AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (context, child) {
        return ClipRect(
          clipper: _RectClipper(animation.value),
          child: child,
        );
      },
    );
  }

  _updateAnimation() {
    if (widget.curve == null && widget.reverseCurve == null) {
      _animation = _controller;
    } else {
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve, reverseCurve: widget.reverseCurve);
    }
  }

  @override
  void didUpdateWidget(AnimatedExtend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curve != widget.curve || oldWidget.reverseCurve != widget.reverseCurve) {
      _updateAnimation();
    }
    _controller.duration = _controller.reverseDuration = widget.duration;
    if (oldWidget.display != widget.display) {
      if (widget.display) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        duration: widget.duration,
        reverseDuration: widget.duration
    );
    _updateAnimation();
    super.initState();
  }

}

class Search extends StatefulWidget {
  final Project project;
  final Context context;

  Search({
    this.project,
    this.context
  });

  @override
  State<StatefulWidget> createState() => SearchState();
}

class SearchState extends State<Search> {
  TextEditingController textController;
  bool showClear = false;
  FocusNode focusNode;
  List<String> searchHits = [];
  GlobalKey<AnimatedListState> _listKey = GlobalKey();

  String template;

  search() {
    setState(() {
      focusNode.unfocus();
    });
    if (textController.text.isNotEmpty) {
      widget.context.reload({
        "key": textController.text
      });
    }
  }

  updateSearchHit(text) {
    Array keys = Context.searchKeys(text, 10);
    for (int i = 0, t = searchHits.length; i < t; ++i) {
      _listKey.currentState?.removeItem(0, (context, animation) => animatedItem(
        key: searchHits[i],
        animation: animation,
      ), duration: Duration(milliseconds: 0));
    }
    searchHits.clear();
    for (int i = 0, t = keys.length; i < t; ++i) {
      String key = keys[i];
      searchHits.add(key);
      _listKey.currentState?.insertItem(i, duration: Duration(milliseconds: 0));
    }
  }

  Widget animatedItem({String key, Animation<double> animation, void Function() onClear, void Function() onTap}) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(key, style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.black54),),
        leading: Icon(Icons.history),
        trailing: IconButton(
            icon: Icon(Icons.clear),
            onPressed: onClear
        ),
        onTap: onTap,
      ),
    );
  }

  onChange(text) {
    if (text.isEmpty && showClear) {
      setState(() {
        showClear = false;
      });
    } else if (text.isNotEmpty && !showClear) {
      setState(() {
        showClear = true;
      });
    }
    if (focusNode.hasFocus) {
      updateSearchHit(text);
    }
  }

  Widget _buildChild(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Stack(
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                      hintText: kt("search"),
                      border: InputBorder.none,
                      hintStyle: Theme.of(context).textTheme.bodyText1.copyWith(
                          color: Colors.black38
                      )
                  ),
                  controller: textController,
                  autofocus: true,
                  focusNode: focusNode,
                  onChanged: onChange,
                  style: Theme.of(context).textTheme.bodyText1.copyWith(
                      color: Colors.black87
                  ),
                  onSubmitted: (text) {
                    search();
                  },
                ),
                Positioned(
                    right: 0,
                    child: AnimatedCrossFade(
                        firstChild: Container(
                          width: 0,
                          height: 0,
                        ),
                        secondChild: IconButton(
                            icon: Icon(Icons.clear),
                            color: Colors.black38,
                            onPressed: () {
                              textController.clear();
                              setState(() {
                                showClear = false;
                              });
                            }
                        ),
                        crossFadeState: showClear ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: Duration(milliseconds: 300)
                    )
                ),
              ],
            ),
            backgroundColor: Colors.white,
            iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.black87),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (focusNode.hasFocus) {
                      search();
                    } else {
                      focusNode.requestFocus();
                    }
                  }
              ),
            ],
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  if (focusNode.hasFocus) {
                    focusNode.unfocus();
                  } else {
                    Navigator.of(context).pop();
                  }
                }
            ),
          ),
          body: Container(
            color: Colors.white,
            child: Stack(
              children: <Widget>[
                CollectionView(
                  context: widget.context,
                  template: template,
                  onTap: (item) async {
                    if (item.type == DataItemType.Data) {
                      Context itemContext = widget.project.createCollectionContext(DETAILS_INDEX, item).control();
                      await gotoDetails(
                        context,
                        project: widget.project,
                        itemContext: itemContext
                      );
                      itemContext.release();
                    }
                  },
                ),
                AnimatedExtend(
                  child: Container(
                    color: Colors.white,
                    child: AnimatedList(
                      key: _listKey,
                      itemBuilder: (context, index, Animation<double> animation) {
                        String key = searchHits[index];
                        return animatedItem(
                            key: key,
                            animation: animation,
                            onClear: () {
                              Context.removeSearchKey(key);
                              searchHits.removeAt(index);
                              _listKey.currentState.removeItem(index, (context, animation) => animatedItem(
                                  key: key,
                                  animation: animation
                              ), duration: Duration(milliseconds: 300));
                            },
                            onTap: () {
                              textController.text = key;
                              search();
                            }
                        );
                      },
                      initialItemCount: searchHits.length,
                    ),
                  ),
                  display: focusNode.hasFocus,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ),
        onWillPop: () async {
          if (focusNode.hasFocus) {
            focusNode.unfocus();
            return false;
          } else {
            return true;
          }
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light
      ),
      child: _buildChild(context),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.context.control();
    textController = TextEditingController();
    focusNode = FocusNode();
    focusNode.addListener(() {
      setState(() {updateSearchHit(textController.text);});
    });

    template = widget.context.temp;
    if (template.isEmpty)
      template = cachedTemplates["assets/roms.xml"];
  }

  @override
  void dispose() {
    widget.context.release();
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }
}

Future<void> gotoSearchPage({
  WidgetBuilder builder,
  BuildContext context,
  Offset center,
}) {
  return Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secAnimation) {
        return builder(context);
      },
      transitionDuration: Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secAnimation, child) {
        return ClipOval(
          clipper: _DisplayRectClipper(center, animation.value),
          child: child,
        );
      }
  ));
}