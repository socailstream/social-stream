import "package:flutter/material.dart";
//This custom text is used for the Labels of TextFields and nothing else
class CustomText extends StatelessWidget{

  final String text;

  const CustomText ({
    super.key,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    
    return Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              );
  }


}