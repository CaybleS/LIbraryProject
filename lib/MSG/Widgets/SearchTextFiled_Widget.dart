// search_widget.dart
import 'package:flutter/material.dart';

class SearchTextFieldWidget extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onSearch;

  const SearchTextFieldWidget({
    super.key,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Contacts Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: (){
              onSearch();
              searchController.clear();
            },
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.blue),
              foregroundColor: WidgetStatePropertyAll(Colors.white),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
