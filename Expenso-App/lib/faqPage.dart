import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({Key? key}) : super(key: key);

  final List<_FAQItem> faqItems = const [
    _FAQItem(
      question: 'How do I reset my password?',
      answer: 'To reset your password, go to the login screen and tap "Forgot Password". Follow the instructions sent to your email.',
    ),
    _FAQItem(
      question: 'How can I enable notifications?',
      answer: 'Go to Settings > Notifications and toggle the switch to enable or disable notifications.',
    ),
    _FAQItem(
      question: 'Is my data safe?',
      answer: 'Yes, we use industry-standard encryption and security measures to keep your data safe.',
    ),
    _FAQItem(
      question: 'How do I delete my account?',
      answer: 'Go to Settings > Delete Account and follow the prompts. Note that this action is irreversible.',
    ),
    _FAQItem(
      question: 'Can I use the app offline?',
      answer: 'Some features are available offline, but for full functionality, an internet connection is recommended.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        itemCount: faqItems.length,
        itemBuilder: (context, index) {
          final item = faqItems[index];
          return _FAQTile(item: item);
        },
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});
}

class _FAQTile extends StatefulWidget {
  final _FAQItem item;
  const _FAQTile({Key? key, required this.item}) : super(key: key);

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        iconColor: primaryColor,
        collapsedIconColor: primaryColor,
        title: Text(
          widget.item.question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.item.answer,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
        onExpansionChanged: (val) {
          setState(() {
            _expanded = val;
          });
        },
      ),
    );
  }
}