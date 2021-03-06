import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/base/base_state.dart';
import 'package:myapp/database/db_api.dart';
import 'package:myapp/entity/contact_entity.dart';
import 'package:myapp/entity/conversation_entity.dart';
import 'package:myapp/entity/group_entity.dart';
// import 'package:myapp/manager/sender_manager.dart';
import 'package:myapp/manager/wssender_manager.dart';
import 'package:myapp/page/message_page.dart';
import 'package:myapp/page/more_widgets.dart';
import 'package:myapp/utils/constants.dart';
import 'package:myapp/utils/date_util.dart';
import 'package:myapp/utils/dialog_util.dart';
import 'package:myapp/utils/interact_vative.dart';
import 'package:myapp/page/contacts_select_page.dart';

class ConversationPage extends StatefulWidget {
  ConversationPage({Key key, this.rootContext}) : super(key: key);
  final BuildContext rootContext;

  @override
  State<StatefulWidget> createState() {
    return new Conversation();
  }
}

class Conversation extends BaseState<ConversationPage>
    with WidgetsBindingObserver {
  var map = Map();
  var list = new List();
  var contactsMap = new Map();
  var groupMap = new Map();
  var _popString = List<String>();
  bool isShowNoPage = false;
  Timer _refreshTimer;
  AppLifecycleState currentState = AppLifecycleState.resumed;
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>(); //TODO

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getData();
    _startRefresh();
    _popString.add('Reconnect');
    _popString.add('Group Chat');
  }

  @override
  Widget build(BuildContext context) {
    return layout(context);
  }

  Widget layout(BuildContext context) {
    return new Scaffold(
        key: _key,
        appBar: _appBar(),
        body: new Stack(
          children: <Widget>[
            new Offstage(
              offstage: isShowNoPage,
              child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return _itemWidget(index);
                  },
                  itemCount: list.length),
            ),
            new Offstage(
              offstage: !isShowNoPage,
              child: MoreWidgets.buildNoDataPage(), //显示loading，则禁掉返回按钮和右滑关闭
            )
          ],
        ));
  }

  _appBar() {
    return MoreWidgets.buildAppBar(
      context,
      'Conversations',
      elevation: 2.0,
      actions: <Widget>[
        InkWell(
            child: Container(
                padding: EdgeInsets.only(right: 15, left: 15),
                child: Icon(
                  Icons.more_horiz,
                  size: 22,
                )),
            onTap: () {
              MoreWidgets.buildDefaultMessagePop(context, _popString,
                  onItemClick: (res) {
                if (res == null) return;
                print("did tap :" + res);
                switch (res) {
                  case 'one':
                    // socket reconnect.
                    DialogUtil.buildToast('Try Reconnect Done.');
                    SenderMngr.init();
                    break;
                  case 'two':
                    Navigator.push(context,
                        new MaterialPageRoute(builder: (ctx) {
                      return ContactsSelectPage();
                    }));
                    break;
                }
              });
            })
      ],
    );
  }

  Widget _itemWidget(int index) {
    Widget res;
    ConversationEntity entity = map[list.elementAt(index).toString()];
    String timeTmp = DateUtil.getDateStrByDateTime(
        DateUtil.getDateTimeByMs(entity.timestamp));
    String time =
        DateUtil.formatDateTime(timeTmp, DateFormat.YEAR_MONTH_DAY, '/', '');
    String portrait = Constants.DEFAULT_PORTRAIT;

    if (entity.conversationType == Constants.CONVERSATION_SINGLE &&
        contactsMap.containsKey(entity.targetUid) &&
        contactsMap[entity.targetUid] != null) {
      portrait = contactsMap[entity.targetUid].portrait;
    } else if (entity.conversationType == Constants.CONVERSATION_GROUP &&
        groupMap.containsKey(entity.targetUid) &&
        groupMap[entity.targetUid] != null) {
      portrait = groupMap[entity.targetUid].portrait;
    }
    res = MoreWidgets.conversationListViewItem(
        entity.name == null ? entity.targetUid : entity.name,
        entity.conversationType,
        portrait: portrait,
        content: entity.lastMessage,
        time: time,
        unread: entity.isUnreadCount, onItemClick: (res) {
      //聊天消息，跳转聊天对话页面
      Navigator.push(
          context,
          new CupertinoPageRoute<void>(
              builder: (ctx) => MessagePage(
                    title: entity.name == null ? entity.targetUid : entity.name,
                    targetUid: entity.targetUid,
                    convId: entity.id,
                    targetUrl: portrait,
                    convType: entity.conversationType,
                  )));
    });
    return res;
  }

  _getData() async {
    //display no page.
    setState(() {
      list.clear();
      map.clear();
      contactsMap.clear();
      groupMap.clear();
      isShowNoPage = true;
    });
  }

  /*
  * 定时刷新
  */
  _startRefresh() {
    _refreshTimer =
        Timer.periodic(const Duration(milliseconds: 1000 * 60), _handleTime);
  }

  _handleTime(Timer timer) {
    //当APP在前台，且当前页是0（即本页），则刷新
    if (null != currentState && currentState != AppLifecycleState.paused) {
      setState(() {
        print('refresh data');
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    //initState后，未调用，所以初始化为resume，当APP进入后台，则为onPause；APP进入前台，为resume
    currentState = state;
    if (currentState == AppLifecycleState.resumed) {
      //reconnect the socket if needed.
      SenderMngr.init();
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (null != _refreshTimer) {
      _refreshTimer.cancel();
    }
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void notify(Object type) async {
    if (type == InteractNative.PULL_CONVERSATION) {
      list.clear();
      map.clear();
      contactsMap.clear();
      groupMap.clear();

      List<ContactEntity> contacts =
          await DataBaseApi.get().getAllContactsEntities();
      contacts.forEach((contact) => contactsMap[contact.userId] = contact);

      List<GroupEntity> groups = await DataBaseApi.get().getAllGroupEntities();
      groups.forEach((group) => groupMap[group.groupId] = group);

      List<ConversationEntity> conversations =
          await DataBaseApi.get().getConversationEntities();
      conversations.forEach((entity) {
        if (entity.conversationType == Constants.CONVERSATION_SINGLE) {
          if (contactsMap.containsKey(entity.targetUid)) {
            entity.name = contactsMap[entity.targetUid].userName;
          }
        } else if (entity.conversationType == Constants.CONVERSATION_GROUP) {
          if (groupMap.containsKey(entity.targetUid)) {
            entity.name = groupMap[entity.targetUid].name;
          }
        }
        list.add(entity.targetUid); //group: GroupId,  single:  target user id.
        map[entity.targetUid] = entity;
      });
      if (this.mounted) {
        setState(() {
          isShowNoPage = conversations.length <= 0;
        });
      }
    }
  }
}
