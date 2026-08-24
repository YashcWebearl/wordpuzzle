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
  bool hasError = false;
  bool canAccept = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPolicy();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!canAccept) {
        setState(() {
          canAccept = true;
        });
      }
    }
  }

  void _checkScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) {
        if (!canAccept) setState(() => canAccept = true);
        return;
      }
      if (_scrollController.position.maxScrollExtent <= 50) {
        if (!canAccept) setState(() => canAccept = true);
      }
    });
  }

  Future<void> _fetchPolicy() async {
    setState(() {
      isLoading = true;
      hasError = false;
      canAccept = false;
    });

    try {
      final response = await http
          .get(Uri.parse('$LURL/api/policy/Wordix/${widget.policyType}'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (data != null && data['content'] != null) {
          setState(() {
            title = data['title'] ??
                (widget.policyType == 'terms_conditions'
                    ? "Terms & Conditions"
                    : "Privacy Policy");
            content = data['content'];
            isLoading = false;
            hasError = false;
          });
          _checkScrollable();
        } else {
          _setError("Failed to load policy.");
        }
      } else {
        _setError("Failed to load policy.");
      }
    } catch (e) {
      _setError("Something went wrong.");
    }
  }

  void _setError(String message) {
    setState(() {
      isLoading = false;
      hasError = true;
      title = "Error";
      content = message;
      canAccept = true; // Enable Accept & Continue on error state
    });
  }

  void _handleAccept() {
    if (!canAccept) return;
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
    final bool hasDetails = !isLoading &&
        !hasError &&
        content != null &&
        content!.trim().isNotEmpty;
    final String defaultTitle = widget.policyType == 'terms_conditions'
        ? "Terms & Conditions"
        : "Privacy Policy";

    return Scaffold(
      body: BackgroundContainer(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // Title Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    child: Text(
                      title ?? defaultTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Main Content Card
                  if (hasDetails)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              content!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // When no details (Loading or Error state), restrict width to max 300 and wrap content height
                    Expanded(
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading) ...[
                                const CircularProgressIndicator(
                                    color: Colors.white),
                                const SizedBox(height: 16),
                                const Text(
                                  "Loading policy...",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ] else if (hasError) ...[
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.orangeAccent,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  content ?? "Failed to load policy.",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _fetchPolicy,
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  label: const Text(
                                    "Retry",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Optional Scroll Hint when details present & scroll needed
                  if (hasDetails && !canAccept)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Scroll down to enable Accept button",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),

                  // Bottom Button Padding & Action
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: canAccept ? _handleAccept : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAccept
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade700,
                          disabledBackgroundColor:
                              Colors.grey.shade700.withOpacity(0.6),
                          elevation: canAccept ? 4 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Accept & Continue",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: canAccept ? Colors.white : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
