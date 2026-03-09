import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TermSection {
  final String title;
  final List<String> paragraphs;

  const _TermSection({required this.title, required this.paragraphs});
}

class TermsScreen extends StatefulWidget {
  static const routeName = '/terms';
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepted = false;
  static const _prefsKey = 'nexora_terms_accepted';

  static const List<_TermSection> _sections = [
    _TermSection(
      title: '1. Eligibility',
      paragraphs: [
        'You must be at least 13 years old (or the minimum age required in your jurisdiction) to use the Service.',
        'If you use the Service on behalf of an organization, you represent and warrant that you are authorized to bind that organization to these Terms.',
      ],
    ),
    _TermSection(
      title: '2. Account Registration and Security',
      paragraphs: [
        'Certain features require an account. You agree to provide accurate information and keep your profile current.',
        'You are responsible for all activity under your account and for keeping your credentials confidential.',
        'You must promptly notify Nexora of any unauthorized account access or security incident.',
      ],
    ),
    _TermSection(
      title: '3. Acceptable Use',
      paragraphs: [
        'You agree to use the Service only for lawful purposes and in compliance with these Terms.',
        'You must not violate applicable laws, reverse engineer the Service where prohibited, transmit malware, disrupt infrastructure, or infringe the rights of others.',
      ],
    ),
    _TermSection(
      title: '4. User Content',
      paragraphs: [
        '"Your Content" means any content you upload, submit, or otherwise make available through the Service.',
        'You retain ownership of Your Content and grant Nexora a non-exclusive, worldwide, royalty-free license to host, store, reproduce, adapt for technical formatting, and display it solely to operate the Service.',
        'You represent and warrant that you have all necessary rights to provide Your Content and grant this license.',
      ],
    ),
    _TermSection(
      title: '5. Prohibited Content',
      paragraphs: [
        'You may not submit content that is illegal, harmful, harassing, defamatory, obscene, or that infringes intellectual property, privacy, or other legal rights.',
      ],
    ),
    _TermSection(
      title: '6. Third-Party Services',
      paragraphs: [
        'The Service may integrate with or link to third-party services. Nexora does not control and is not responsible for third-party services.',
        'Your use of third-party services is governed by their own terms and policies.',
      ],
    ),
    _TermSection(
      title: '7. Intellectual Property',
      paragraphs: [
        'The Service, including software, design, text, graphics, and trademarks, is owned by Nexora or its licensors and protected by applicable law.',
        'You are granted a limited, non-exclusive, non-transferable, revocable license to use the Service for personal or internal business use, subject to these Terms.',
      ],
    ),
    _TermSection(
      title: '8. Feedback',
      paragraphs: [
        'If you provide feedback, suggestions, or ideas, Nexora may use them without restriction or compensation.',
      ],
    ),
    _TermSection(
      title: '9. Termination',
      paragraphs: [
        'You may stop using the Service at any time.',
        'Nexora may suspend or terminate access if you violate these Terms, create legal or security risk, or if required by law.',
      ],
    ),
    _TermSection(
      title: '10. Disclaimer of Warranties',
      paragraphs: [
        'The Service is provided "as is" and "as available" to the maximum extent permitted by law.',
        'Nexora disclaims all implied warranties, including merchantability, fitness for a particular purpose, and non-infringement.',
      ],
    ),
    _TermSection(
      title: '11. Limitation of Liability',
      paragraphs: [
        'To the fullest extent permitted by law, Nexora is not liable for indirect, incidental, special, consequential, or punitive damages, including lost profits, data, or goodwill.',
        'Nexora\'s aggregate liability is limited to the amount paid for the Service in the prior 12 months, or USD 100 if no amount was paid.',
      ],
    ),
    _TermSection(
      title: '12. Indemnification',
      paragraphs: [
        'You agree to indemnify and hold harmless Nexora and its affiliates, officers, employees, and agents from claims, losses, liabilities, and expenses arising from your use of the Service or violation of these Terms.',
      ],
    ),
    _TermSection(
      title: '13. Privacy',
      paragraphs: [
        'Collection and use of personal data is governed by Nexora\'s Privacy Policy.',
      ],
    ),
    _TermSection(
      title: '14. Changes to Terms',
      paragraphs: [
        'Nexora may update these Terms from time to time. Continued use after updates become effective constitutes acceptance of the revised Terms.',
      ],
    ),
    _TermSection(
      title: '15. Governing Law and Dispute Resolution',
      paragraphs: [
        'These Terms are governed by the laws of the jurisdiction where Nexora is established, excluding conflict-of-law principles.',
        'Disputes shall be resolved in the courts of that jurisdiction unless applicable law requires otherwise.',
      ],
    ),
    _TermSection(
      title: '16. Contact Information',
      paragraphs: [
        'Questions regarding these Terms may be sent to: nexora291802@gmail.com',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAccepted();
  }

  Future<void> _loadAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _accepted = prefs.getBool(_prefsKey) ?? false);
  }

  Future<void> _setAccepted(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, v);
    if (mounted) setState(() => _accepted = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 1.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          'NEXORA TERMS AND CONDITIONS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 10),
                        SelectableText(
                          'Last Updated: January 11, 2026',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        SelectableText(
                          'These Terms and Conditions govern your access to and use of Nexora, including the mobile application, website, and related services. By accessing or using the Service, you agree to be bound by these Terms.',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._sections.map(
                    (section) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            section.title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 7),
                          ...section.paragraphs.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: SelectableText(
                                p,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                activeColor: Colors.black,
                checkColor: Colors.white,
                title: const Text(
                  'I have read and agree to the Terms and Conditions',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              value: _accepted,
              onChanged: (v) => _setAccepted(v ?? false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
