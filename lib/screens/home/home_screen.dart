import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/material.dart';
import 'package:fun_with_flutter/blocs/filtered_blog/filtered_blog.dart';
import 'package:fun_with_flutter/blocs/page/page.dart';
import 'package:fun_with_flutter/components/menu_drawer.dart';
import 'package:fun_with_flutter/themes/app_colors.dart';
import 'package:fun_with_flutter/widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static final double menuSize = 300;

  final Duration animationDuration = Duration(milliseconds: 100);
  AnimationController _controller;
  Animation<double> menuAnimation;
  Tween<double> tween = Tween<double>()
    ..begin = 0
    ..end = menuSize;

  bool menuVisible = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: animationDuration);
    menuAnimation = tween.animate(_controller);
    _controller.addStatusListener(_setMenuVisibleOnAnimationStatusChange);

    super.initState();
  }

  void _setMenuVisibleOnAnimationStatusChange(status) {
    if (status == AnimationStatus.forward) {
      menuVisible = true;
    } else if (status == AnimationStatus.dismissed) {
      menuVisible = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fun with Flutter',
          style: Theme.of(context).textTheme.display1,
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (menuVisible) {
              _controller.reverse();
            } else {
              _controller.forward();
            }
          },
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: menuAnimation,
            color: fadedBlack,
          ),
        ),
        elevation: 1,
      ),
      body: AnimatedBuilder(
        animation: menuAnimation,
        builder: (context, widget) {
          return Stack(
            children: <Widget>[
              if (menuVisible)
                Transform.translate(
                  offset: Offset(-menuSize + menuAnimation.value, 0),
                  child: MenuDrawer(
                    width: menuSize,
                  ),
                ),
              Row(
                children: <Widget>[
                  _EmptyContainerPusher(menuAnimation.value),
                  BlocBuilder(
                    bloc: BlocProvider.of<PageBloc>(context),
                    builder: (BuildContext context, PageState state) {
                      if (state == PageState.home) {
                        return Expanded(child: _Home());
                      } else if (state == PageState.tagsFilter) {
                        return Expanded(
                          child: _FilteredPosts(),
                        );
                      } else if (state == PageState.widget) {
                        return Expanded(child: Text('Todo widgets'));
                      } else if (state == PageState.about) {
                        return Expanded(child: Text('Todo about'));
                      } else {
                        return Expanded(
                          child: (Text(
                              "Whoops you found something that's not yet implemented.")),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

class _FilteredPosts extends StatefulWidget {
  @override
  _FilteredPostsState createState() => _FilteredPostsState();
}

class _FilteredPostsState extends State<_FilteredPosts>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Tween<double> _paddingTween = Tween<double>(begin: 64, end: 32);
  Animation<double> _paddingAnimation;
  AnimationStatus _animationStatus;
  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    )..addStatusListener(_animationStatusListener);
    _paddingAnimation = _paddingTween.animate(CurvedAnimation(
      curve: Curves.easeOut,
      parent: _animationController,
    ));
    _animationController.forward();

    super.initState();
  }

  void _animationStatusListener(AnimationStatus status) {
    _animationStatus = status;
  }

  // Only restarts the animation if it is already completed, to avoid jittery behaviour on screen resize
  void _restartAnimation() {
    if (_animationStatus == AnimationStatus.completed) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var bouncingScrollPhysics = BouncingScrollPhysics();
    return BlocBuilder(
      bloc: BlocProvider.of<FilteredBlogBloc>(context),
      builder: (BuildContext context, FilteredBlogState state) {
        if (state is FilteredBlogLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is FilteredBlogLoaded) {
          _restartAnimation();
          return AnimatedBuilder(
            animation: _paddingAnimation,
            builder: (context, child) {
              return Padding(
                padding:
                    EdgeInsets.symmetric(vertical: _paddingAnimation.value),
                child: GridView.extent(
                  maxCrossAxisExtent: 400,
                  padding: const EdgeInsets.all(16),
                  physics: bouncingScrollPhysics,
                  children: <Widget>[
                    for (var page in state.filteredBlog.pages)
                      PostCard(
                        post: page,
                      )
                  ],
                ),
              );
            },
          );
        }
        return Text('Something went wrong');
      },
    );
  }
}

Container _EmptyContainerPusher(double width) {
  return Container(
    width: width,
  );
}