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

class _LeakLookupScreenState extends State<LeakLookupScreen> with TickerProviderStateMixin {
  final ToolsRepository _repository = ToolsRepository();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _limitController = TextEditingController(text: '100');

  bool _isLoading = false;
  String _language = 'en';
  Map<String, dynamic>? _result;
  String? _errorMessage;
  bool _showJson = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _queryController.text = widget.initialQuery!;
    }
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _limitController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _runLookup() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter a phone number or query'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    int limit = int.tryParse(_limitController.text.trim()) ?? 100;
    limit = limit.clamp(1, 10000);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showJson = false;
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
      _slideController.forward(from: 0);
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                    const Color(0xFF312E81),
                  ]
                : [
                    const Color(0xFFF0F9FF),
                    const Color(0xFFE0E7FF),
                    const Color(0xFFDDD6FE),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchCard(isDark),
                      const SizedBox(height: 20),
                      _buildResultSection(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.9),
            const Color(0xFF8B5CF6).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leak Lookup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Security Intelligence Search',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reset',
            onPressed: _isLoading
                ? null
                : () {
                    _queryController.clear();
                    _limitController.text = '100';
                    setState(() {
                      _result = null;
                      _errorMessage = null;
                      _showJson = false;
                    });
                  },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Search Parameters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _queryController,
            label: 'Query',
            hint: '+989123456789',
            icon: Icons.phone_android_rounded,
            iconColor: const Color(0xFF6366F1),
            isDark: isDark,
            onPaste: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null) {
                _queryController.text = data!.text!;
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _limitController,
                  label: 'Limit',
                  hint: '100',
                  icon: Icons.filter_list_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageDropdown(isDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    VoidCallback? onPaste,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: onPaste != null
            ? IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 20),
                tooltip: 'Paste',
                onPressed: _isLoading ? null : onPaste,
              )
            : null,
        filled: true,
        fillColor: isDark 
            ? const Color(0xFF0F172A).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: iconColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _language,
        decoration: InputDecoration(
          labelText: 'Language',
          prefixIcon: const Icon(Icons.translate_rounded, color: Color(0xFF10B981), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'ru', child: Text('Russian')),
          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
        ],
        onChanged: _isLoading
            ? null
            : (value) {
                if (value != null) {
                  setState(() => _language = value);
                }
              },
      ),
    );
  }

  Widget _buildSearchButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _runLookup,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isLoading ? 'Searching...' : 'Start Search',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(bool isDark) {
    if (_errorMessage != null) {
      return _buildErrorCard(isDark);
    }

    if (_result == null) {
      return _buildEmptyState(isDark);
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _slideController,
        child: Column(
          children: [
            _buildResultStats(isDark),
            const SizedBox(height: 16),
            _buildResultCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStats(bool isDark) {
    final List<dynamic> data = _result?['Data'] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.2),
            const Color(0xFF059669).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search Complete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.length} results found',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showJson ? Icons.view_list_rounded : Icons.code_rounded,
              color: const Color(0xFF10B981),
            ),
            tooltip: _showJson ? 'Card View' : 'JSON View',
            onPressed: () {
              setState(() => _showJson = !_showJson);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isDark) {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(_result);

    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B).withOpacity(0.7)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dataset_rounded, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_all_rounded, size: 20),
                tooltip: 'Copy JSON',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: prettyJson));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Copied to clipboard'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_showJson)
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SelectableText(
                    prettyJson,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            )
          else
            _buildDataCards(isDark),
        ],
      ),
    );
  }

  Widget _buildDataCards(bool isDark) {
    final List<dynamic> data = _result?['Data'] ?? [];
    
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No data available'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length > 10 ? 10 : data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = data[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF0F172A).withOpacity(0.5)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                item.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          constraints: const BoxConstraints(minHeight: 300),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1E293B).withOpacity(0.7)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1 + (_pulseController.value * 0.1)),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: Color(0xFF6366F1),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Search',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your query above and click\n"Start Search" to begin',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B).withOpacity(0.7)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Search Failed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}