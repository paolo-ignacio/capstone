import 'package:flutter/material.dart'; 
import 'package:gap/gap.dart';
import 'package:legallyai/screens/template_screens/customize_template_screen.dart';
import 'package:legallyai/screens/template_screens/recent_file_screen.dart';

class TemplatesScreen extends StatefulWidget {
  TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final List<String> dates = ["Yesterday", "2 days ago", "2 days ago"];

  final List<String> titles = ["Lease Agreements", "Employment Contracts", "Lease Agreements"];

  final List<Color> colorsDocs = [Color(0xFF1565C0), Color(0xFF7B1FA2), Color(0xFF2E7D32)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C2E),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Template Library",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search, color: Colors.white)),
          IconButton(onPressed: () {}, icon: Icon(Icons.sort, color: Colors.white)),
        ],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Recent files", style: TextStyle(color: Colors.black54, fontSize: 14)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1C1C2E))),
                    const SizedBox(height: 4),
                    Container(height: 2, width: 40, color: Color(0xFFD4AF37)),
                  ],
                ),
                const Gap(12),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: titles.length,
                    itemBuilder: (_, index) {
                      return Container(
                        width: 117,
                        height: 107,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: (){
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditRecentFileScreen()));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Gap(8),
                              Center(child: Image.asset('assets/images/docs.png', width: 150, height: 70)),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1C1C2E),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        titles[index],
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        dates[index],
                                        style: TextStyle(fontSize: 12, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(10),
                const Divider(thickness: 1.5, color:Color.fromRGBO(28, 28, 46, 0.1)),
                const Gap(10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Templates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1C1C2E))),
                    const SizedBox(height: 4),
                    Container(height: 2, width: 40, color: Color(0xFFD4AF37)),
                  ],
                ),
                const Gap(12),
                _sectionTitle(context, "Contracts and Agreements"),
                const Gap(8),
                _templateSection(["Sales Contract", "Partnership Agreement", "Service Agreement", "MOA"]),
                const Gap(12),
                _sectionTitle(context, "Property and Real Estate Documents"),
                const Gap(8),
                _templateSection(["Deed of Sale", "Land Title", "Mortgage Agreement", "Lease Form"]),
                const Gap(12),
                _sectionTitle(context, "Legal Proceedings and Court Documents"),
                const Gap(8),
                _templateSection(["Complaint", "Summons", "Affidavit", "Court Order"]),
                const Gap(12),
                _sectionTitle(context, "Financial and Banking Documents"),
                const Gap(8),
                _templateSection(["Promissory Note", "Loan Agreement", "Bank Guarantee", "Check Template"]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1C1C2E),
              ),
        ),
      ),
    );
  }

  Widget _templateSection(List<String> items) {
    final List<IconData> iconOptions = [
      Icons.insert_drive_file,
      Icons.file_copy,
      Icons.picture_as_pdf,
      Icons.folder,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 3 / 2,
        ),
        itemBuilder: (_, index) {
          return index == 3
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.more_horiz, size: 32, color: Colors.grey[700]),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => print("See More clicked"),
                        child: Text(
                          "See More",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                 onTap: (){
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomizePartnershipAgreementScreen()));
                },
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          iconOptions[index % iconOptions.length],
                          size: 32,
                          color: colorsDocs[index % colorsDocs.length],
                        ),
                        const Spacer(),
                        Text(
                          items[index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              );
        },
      ),
    );
  }
}
