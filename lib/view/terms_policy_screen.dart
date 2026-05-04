import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:word_puzzle/view/home_screen.dart';
import '../Widget/base_url.dart';
import '../Widget/bg_container.dart';

class TermsAndPolicyScreen extends StatefulWidget {
  final String policyType; // 'terms_conditions' or 'privacy_policy'

  const TermsAndPolicyScreen({super.key, required this.policyType});

  @override
  State<TermsAndPolicyScreen> createState() => _TermsAndPolicyScreenState();
}

class _TermsAndPolicyScreenState extends State<TermsAndPolicyScreen> {
  String? title;
  String? content;
  bool isLoading = true;
  bool canAccept = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPolicy();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!canAccept) {
        setState(() {
          canAccept = true;
        });
      }
    }
  }

  Future<void> _fetchPolicy() async {
    try {
      final response = await http.get(
        Uri.parse('$LURL/api/policy/Wordix/${widget.policyType}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          title = data['title'];
          content = data['content'];
          isLoading = false;
        });

        // Check if content is short enough that it doesn't need scrolling
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients &&
              _scrollController.position.maxScrollExtent <= 0) {
            setState(() {
              canAccept = true;
            });
          }
        });
      } else {
        setState(() {
          isLoading = false;
          title = "Error";
          content = "Failed to load policy.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        title = "Error";
        content = "Something went wrong.";
      });
    }
  }

  void _handleAccept() {
    if (widget.policyType == 'terms_conditions') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const TermsAndPolicyScreen(policyType: 'privacy_policy'),
        ),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  title ??
                      (widget.policyType == 'terms_conditions'
                          ? "Terms & Conditions"
                          : "Privacy Policy"),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Text(
                              content ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  onPressed: canAccept ? _handleAccept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAccept ? Colors.green : Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Accept & Continue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
