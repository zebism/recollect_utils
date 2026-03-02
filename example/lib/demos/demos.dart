import 'package:flutter/material.dart';
import 'package:recollect_utils/recollect_utils.dart';

class Demos extends StatefulWidget {
  const Demos({super.key});

  @override
  State<Demos> createState() => _DemosState();
}

class _DemosState extends State<Demos> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height * 1,
          width: MediaQuery.of(context).size.width * 1,
          color: AppTheme.background(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SimpleMenu(
                items: menuItems,
                setStateCallback: () => setState(() {}),
              ),
              FilteredMenu(
                items: menuItems,
                height: 35,
                width: 200,
                setStateCallback: () => setState(() {}),
              ),
              SuggestionField(
                alignDropdown: AlignType.left,
                alignDropdownText: TextAlign.center,

                height: 35,
                width: 200,
                items: ints,
                onSelected: (value) {
                  print(value);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<int> ints = [8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24, 26, 28, 36, 48, 72];
List<MenuItem> menuItems = [
  MenuItem(label: 'First', value: '1'),
  MenuItem(label: 'Second', value: '2'),
  MenuItem(label: 'Third', value: '3'),
  MenuItem(label: 'Fourth', value: '4'),
  MenuItem(label: 'Fifth', value: '5'),
];
