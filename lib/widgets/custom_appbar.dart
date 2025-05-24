import 'package:flutter/material.dart';

import '../global/colors.dart';
import '../views/uploadfiles.dart';
import 'logoutbutton.dart';
import 'openlinkmodal.dart';

AppBar buildCustomAppBar(bool showBackOption) {
  return AppBar(
    backgroundColor: const Color(0xFF003366),
    title: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock, color: Colors.orange, size: 20),
        SizedBox(width: 6),
        Text("SafeBoX",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    ),
    actions: const [
      Padding(
        padding: EdgeInsets.only(right: 12.0),
        child: LogoutButton(),
      )
    ],
    leading: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: PopupMenuButton(
        icon: const Icon(
          Icons.menu,
          color: mainTextColor,
        ),
        itemBuilder: (context) =>
        showBackOption ? buildWithBackOption(context) : buildWithoutBackOption(context),
      ),
    ),
  );
}

List<PopupMenuEntry<dynamic>> buildWithoutBackOption(BuildContext context) {
        return [
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.link, color: Colors.black),
                SizedBox(width: 8),
                Text("Open Link", style: TextStyle(color: Colors.black)),
              ],
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const OpenLinkModal(),
              );
            },
          ),
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.add_box, color: Colors.black),
                SizedBox(width: 8),
                Text("Add File", style: TextStyle(color: Colors.black)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadFilesPage(),
                )
              );
            },
          ),
          const PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.black),
                SizedBox(width: 8),
                Text("Notifications",
                    style: TextStyle(color: Colors.black)),
              ],
            ),
          )
        ];
      }

List<PopupMenuEntry<dynamic>> buildWithBackOption(BuildContext context) {
  return [
    PopupMenuItem(
      child: const Row(
        children: [
          Icon(Icons.arrow_back, color: Colors.black),
          SizedBox(width: 8),
          Text("Back", style: TextStyle(color: Colors.black)),
        ],
      ),
      onTap: () {
        Navigator.pop(context);
      },
    ),
    PopupMenuItem(
      child: const Row(
        children: [
          Icon(Icons.link, color: Colors.black),
          SizedBox(width: 8),
          Text("Open Link", style: TextStyle(color: Colors.black)),
        ],
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const OpenLinkModal(),
        );
      },
    ),
    const PopupMenuItem(
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: Colors.black),
          SizedBox(width: 8),
          Text("Notifications",
              style: TextStyle(color: Colors.black)),
        ],
      ),
    ),
  ];
}