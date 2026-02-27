import '../models/resume_record.dart';

/// Handles QR encoding for candidate records.
/// Output is a clean multi-line string: Name, Phone, Email, LinkedIn, Skills.
class QrService {
  /// Encode a record into a clean multi-line string suitable for QR.
  static String encodeRecord(ResumeRecord record) {
    final ext = record.extracted;
    String qrData = '';

    if (record.candidateName.trim().isNotEmpty) {
      qrData += 'Name: ${record.candidateName.trim()}\n';
    }
    if (record.primaryPhone.trim().isNotEmpty) {
      qrData += 'Phone: ${record.primaryPhone.trim()}\n';
    }
    if (record.primaryEmail.trim().isNotEmpty) {
      qrData += 'Email: ${record.primaryEmail.trim()}\n';
    }
    if (ext.linkedinUrls.isNotEmpty) {
      final val = ext.linkedinUrls.first.value.trim();
      if (val.isNotEmpty) {
        qrData += 'LinkedIn: $val\n';
      }
    }

    final validSkills = ext.skills
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (validSkills.isNotEmpty) {
      qrData += 'Skills: ${validSkills.join(', ')}\n';
    }

    qrData = qrData.trimRight(); // Clean trailing newline

    // ignore: avoid_print
    print('QR STRING OUTPUT:\n$qrData');
    return qrData;
  }
}
