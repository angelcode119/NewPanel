import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/repositories/tools_repository.dart';

class LeakLookupScreen extends StatefulWidget {
  final String? initialQuery;

  const LeakLookupScreen({super.key, this.initialQuery});

  @override
  State<LeakLookupScreen> createState() => _LeakLookupScreenState();
}

class _LeakLookupScreenState extends State<LeakLookupScreen> {
  final ToolsRepository _repository = ToolsRepository();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _limitController = TextEditingController(text: '100');

  bool _isLoading = false;
  String _language = 'en';
  Map<String, dynamic>? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _queryController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _runLookup() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number or query')),
      );
      return;
    }

    int limit = int.tryParse(_limitController.text.trim()) ?? 100;
    limit = limit.clamp(1, 10000);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.lookupLeak(
        query: query,
        limit: limit,
        lang: _language,
      );
      setState(() {
        _result = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _result = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leak Lookup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: 'Clear form',
            onPressed: _isLoading
                ? null
                : () {
                    _queryController.clear();
                    _limitController.text = '100';
                    setState(() {
                      _result = null;
                      _errorMessage = null;
                    });
                  },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _queryController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Phone number or query',
                hintText: '+919876543210',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            _queryController.text = data!.text!;
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Limit',
                      hintText: '100',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _language,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ru', child: Text('Russian')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _language = value;
                              });
                            }
                          },
                    decoration: const InputDecoration(
                      labelText: 'Language',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(_isLoading ? 'Looking up...' : 'Lookup'),
                onPressed: _isLoading ? null : _runLookup,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: _buildResultView(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Text(
          'No results to show',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
      );
    }

    final prettyJson = const JsonEncoder.withIndent('  ').convert(_result);

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: SelectableText(
          prettyJson,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}

