import 'package:flutter/material.dart';

class EditRecentFileScreen extends StatelessWidget {
  const EditRecentFileScreen({super.key});

  final String fileName = "Service Contract";

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
          // Formatting Toolbar
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
          // Editor Area
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
SERVICE AGREEMENT

This Service Agreement ("Agreement") is made and entered into this 10th day of May, 2025, by and between:

Juan Dela Cruz, of legal age, with address at 123 Barangay Sto. Niño, Quezon City, Philippines ("Client");

and

Maria Santos, of legal age, with address at 456 Rizal Avenue, Makati City, Philippines ("Service Provider").

WITNESSETH:

WHEREAS, the Client desires to engage the Service Provider for the performance of certain services;  
WHEREAS, the Service Provider agrees to provide such services under the terms and conditions set forth herein;

NOW, THEREFORE, for and in consideration of the foregoing premises and the mutual covenants herein contained, the parties hereby agree as follows:

1. Scope of Services  
The Service Provider agrees to perform the following services: Website design, development, and deployment for the Client’s business, including but not limited to layout design, content integration, and technical support. Any revisions or additional services not specified herein shall be subject to mutual agreement and may require a written amendment to this Agreement.

2. Compensation  
The Client shall pay the Service Provider the amount of One Hundred Thousand Philippine Pesos (₱100,000.00) for the services rendered. Payments shall be made via bank transfer to the Service Provider’s account (Account No. 1234-5678-91011) within thirty (30) days upon presentation of invoice.

3. Term and Termination  
This Agreement shall take effect on May 10, 2025, and shall continue until the completion of the services or until terminated by either party upon fifteen (15) days' prior written notice. If terminated early, the Service Provider shall be compensated for work completed up until the termination date.

4. Confidentiality  
The Service Provider agrees to keep strictly confidential all information, data, and materials disclosed by the Client during the term of this Agreement and thereafter. This includes but is not limited to business plans, strategies, customer lists, and trade secrets.

5. Force Majeure  
Neither party shall be liable for delays or failure in performance resulting from causes beyond its reasonable control, including but not limited to acts of God, war, strikes, or government restrictions.

6. Governing Law and Dispute Resolution  
This Agreement shall be governed by the laws of the Republic of the Philippines. Any dispute arising from this Agreement shall be submitted to the proper courts of Makati City, to the exclusion of all others.

IN WITNESS WHEREOF, the parties have hereunto affixed their signatures this 10th day of May, 2025, in Makati City, Philippines.

___________________________           ___________________________  
Juan Dela Cruz                          Maria Santos  
Client                                  Service Provider
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
        ],
      ),
    );
  }
}
