import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';

class Model {
  Model(this.title, this.onTap);

  String title;
  VoidCallback onTap;
}

class MainPage extends StatefulWidget {
  final String data;

  const MainPage({Key key, this.data}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  TextEditingController _controller = TextEditingController();

  GlobalKey<ScaffoldState> key = GlobalKey();

  VoidCallback removeListener;

  @override
  void initState() {
    super.initState();

    ///这里添加监听，原生利用'event'这个key发送过来消息的时候，下面的函数会调用，
    ///这里就是简单的在flutter上弹一个弹窗
    removeListener =
        BoostChannel.instance.addEventListener("event", (key, arguments) {
      OverlayEntry entry = OverlayEntry(builder: (_) {
        return Center(
            child: Material(
          color: Colors.transparent,
          child: Container(
            alignment: Alignment.center,
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(4)),
            child: Text('这是native传来的参数：${arguments.toString()}',
                style: TextStyle(color: Colors.white)),
          ),
        ));
      });

      Overlay.of(context).insert(entry);

      Future.delayed(const Duration(seconds: 2), () {
        entry.remove();
      });
      return;
    });
  }

  @override
  void dispose() {
    ///记得解除注册
    removeListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ///
    ///Focus on code below to know the basic API
    ///大家重点关注这个Model里面各个API的调用，其他的都是UI的布局可以不用看
    ///
    List<Model> models = [
      Model("open native page", () {
        BoostNavigator.instance.push("homePage", arguments: {
          'data': _controller.text
        }).then((value) => showTipIfNeeded(value.toString()));
      }),
      Model("return to native page with data", () {
        Map<String, Object> result = {'data': _controller.text};
        BoostNavigator.instance.pop(result);
      }),
      Model("open flutter page with container", () {
        BoostNavigator.instance.push("simplePage",
            withContainer: true,
            arguments: {
              'data': _controller.text
            }).then((value) => showTipIfNeeded(value.toString()));
      }),
      Model("open flutter page without container", () {
        BoostNavigator.instance.push("simplePage",
            withContainer: false,
            arguments: {
              'data': _controller.text
            }).then((value) => showTipIfNeeded(value.toString()));
      }),
      Model("open lifecycle test page", () {
        BoostNavigator.instance.push(
          "lifecyclePage",
          withContainer: true,
        );
      }),
      Model("push replacement with Container", () {
        BoostNavigator.instance.pushReplacement(
          "replacementPage",
          withContainer: true,
        );
      }),
      Model("push replacement without container", () {
        BoostNavigator.instance.pushReplacement(
          "replacementPage",
          withContainer: false,
        );
      }),
      Model("open dialog with container", () {
        BoostNavigator.instance.push("dialogPage",
            withContainer: true,

            ///如果开启新容器，需要指定opaque为false
            opaque: false);
      }),
      Model("send event to native", () {
        ///传值给原生
        BoostChannel.instance
            .sendEventToNative("event", {'data': "event from flutter"});
        BoostNavigator.instance.pop();
      }),
    ];

    ///You don't need to take care about the code below
    ///你不需要关心下面的UI代码
    ///==========================================================

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: key,
        appBar: CupertinoNavigationBar(
          leading: CupertinoNavigationBarBackButton(
            onPressed: () {
              BoostNavigator.instance.pop();
            },
          ),
          middle: Text('FlutterBoost Example'),
        ),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            emptyBox(0, 50),
            _buildHeader(),
            emptyBox(0, 30),
            SliverToBoxAdapter(
                child: Center(
              child: Text('Data String is: ${widget.data}',
                  style: TextStyle(fontSize: 30)),
            )),
            emptyBox(0, 30),
            SliverList(
                delegate: SliverChildBuilderDelegate(
                    (ctx, index) => item(models[index]),
                    childCount: models.length)),
            emptyBox(0, 50),
          ],
        ),
      ),
    );
  }

  Widget emptyBox(double width, double height) {
    return SliverToBoxAdapter(
      child: SizedBox(
        width: width,
        height: height,
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CupertinoTextField(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          controller: _controller,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5), color: Colors.amber),
          placeholder: 'input data ',
          placeholderStyle: TextStyle(color: Colors.black38),
        ),
      ),
    );
  }

  Widget item(Model model) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(vertical: 15),
        onPressed: model.onTap,
        child: Text(model.title,
            style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  void showTipIfNeeded(String value) {
    if (value == null || value == 'null' || value.isEmpty) {
      return;
    }
    final bar = SnackBar(
        content: Text('return value is $value'),
        duration: const Duration(seconds: 1));
    key.currentState.showSnackBar(bar);
  }
}
