import 'package:flutter/material.dart';

class CustomizePartnershipAgreementScreen extends StatelessWidget {
  const CustomizePartnershipAgreementScreen({super.key});

  final String fileName = "Partnership Agreement";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2A3C),
      appBar: AppBar(
        title: Text(fileName),
        centerTitle: true,
        backgroundColor: const Color(0xFF2A2A3C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {}, // Placeholder
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {}, // Placeholder
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: const [
                Icon(Icons.format_bold, color: Color(0xFF2A2A3C)),
                SizedBox(width: 12),
                Icon(Icons.format_italic, color: Color(0xFF2A2A3C)),
                SizedBox(width: 12),
                Icon(Icons.format_underline, color: Color(0xFF2A2A3C)),
                SizedBox(width: 12),
                Icon(Icons.format_align_left, color: Color(0xFF2A2A3C)),
                SizedBox(width: 12),
                Icon(Icons.format_align_center, color: Color(0xFF2A2A3C)),
                SizedBox(width: 12),
                Icon(Icons.format_align_right, color: Color(0xFF2A2A3C)),
                SizedBox(width: 12),
                Icon(Icons.format_list_bulleted, color: Color(0xFF2A2A3C)),
                SizedBox(width: 12),
                Icon(Icons.format_list_numbered, color: Color(0xFF2A2A3C)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable document
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Container(
                  width: 800,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: TextEditingController(
                      text: '''
PARTNERSHIP AGREEMENT

This Partnership Agreement ("Agreement") is made and entered into this __________ [Date], by and between:

__________ [Full Name], of legal age, [Citizenship], and resident of __________ [Address]

and

__________ [Full Name], of legal age, [Citizenship], and resident of __________ [Address].

Collectively referred to herein as the "Partners".

1. Business Name and Purpose  
The Partners agree to operate under the business name: __________ [Business Name], with the purpose of __________ [Business Purpose].

2. Principal Place of Business  
The principal office shall be located at __________ [Business Address].

3. Capital Contributions  
- __________ [Partner 1 Name]: ₱__________ [Amount]  
- __________ [Partner 2 Name]: ₱__________ [Amount]

4. Profit and Loss Sharing  
Profits and losses shall be divided equally (50% each).

5. Management and Authority  
All decisions require mutual consent.

6. Books and Records  
Books will be maintained and audited annually.

7. Banking  
All partnership funds shall be kept in a bank account named __________ [Bank Account Name].

8. Duration  
This partnership shall continue unless terminated by mutual agreement, insolvency, death, or withdrawal.

9. Dispute Resolution  
Disputes shall be resolved amicably or through arbitration under [Applicable Law].

IN WITNESS WHEREOF, the parties have signed this on __________ [Date], at __________ [Location].

___________________________           ___________________________  
__________ [Partner 1 Name]           __________ [Partner 2 Name]  
Partner                               Partner
''',
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      height: 1.6,
                      fontFamily: 'Georgia',
                    ),
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration.collapsed(
                      hintText: "Start editing...",
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
          padding: const EdgeInsets.only(left: 24, right:24, top: 0, bottom: 20,),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {}, // Placeholder for action
              icon: const Icon(Icons.edit_document, color: Color(0xFF1C1C2E)),
              label: const Text("Customize Template"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF1C1C2E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
