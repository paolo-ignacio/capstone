class LegalAnalysis {
  final String summaryHighlights;
  final List<String> keyClauses;
  final List<String> actionableInsights;
  final List<String> potentialRisks;
  final List<String> recommendations;
  final Map<String, dynamic> metadata;

  LegalAnalysis({
    required this.summaryHighlights,
    required this.keyClauses,
    required this.actionableInsights,
    required this.potentialRisks,
    required this.recommendations,
    this.metadata = const {},
  });

  factory LegalAnalysis.fromJson(Map<String, dynamic> json) {
    return LegalAnalysis(
      summaryHighlights: _ensureString(json['summary_highlights']),
      keyClauses: _ensureStringList(json['key_clauses']),
      actionableInsights: _ensureStringList(json['actionable_insights']),
      potentialRisks: _ensureStringList(json['potential_risks']),
      recommendations: _ensureStringList(json['recommendations']),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  static String _ensureString(dynamic value) {
    if (value is String) return value;
    if (value == null) return 'No information available';
    return value.toString();
  }

  static List<String> _ensureStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String) {
      return [value];
    }
    return ['No information available'];
  }
}