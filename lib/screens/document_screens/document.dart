import 'package:flutter/material.dart';

class DocsScaffold extends StatelessWidget {
  const DocsScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light grey background for the scaffold
      appBar: AppBar(
        title: const Text('Sales Agreement Document'),
        backgroundColor: Colors.blueGrey[800], // Darker AppBar for a better contrast
      ),
      body: Column(
        children: [
          // Toolbar with formatting options
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                Icon(Icons.format_bold, size: 24, color: Colors.blueGrey),
                SizedBox(width: 8),
                Icon(Icons.format_italic, size: 24, color: Colors.blueGrey),
                SizedBox(width: 8),
                Icon(Icons.format_underlined, size: 24, color: Colors.blueGrey),
                // Add more formatting icons as needed
              ],
            ),
          ),

          // "Paper" document area
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity, // Makes the container responsive
                constraints: BoxConstraints(maxWidth: 800), // Maximum width for larger screens
                padding: const EdgeInsets.all(24.0),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    'Type your sales agreement here...',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
