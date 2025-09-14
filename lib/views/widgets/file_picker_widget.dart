import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerWidget extends StatelessWidget {
  final Function(PlatformFile file) onFileSelected;
  final VoidCallback onClose;

  const FilePickerWidget({
    super.key,
    required this.onFileSelected,
    required this.onClose,
  });

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        onFileSelected(file);
        onClose();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçme hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Dosya Seç',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // File type options
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFileTypeOption(
                  icon: Icons.folder_open,
                  label: 'Tüm Dosyalar',
                  color: Colors.blue,
                  onTap: () => _pickFile(context),
                ),
                _buildFileTypeOption(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: Colors.red,
                  onTap: () => _pickFileByType(context, FileType.custom, allowedExtensions: ['pdf']),
                ),
                _buildFileTypeOption(
                  icon: Icons.description,
                  label: 'Word',
                  color: Colors.blue[700]!,
                  onTap: () => _pickFileByType(context, FileType.custom, allowedExtensions: ['doc', 'docx']),
                ),
                _buildFileTypeOption(
                  icon: Icons.table_chart,
                  label: 'Excel',
                  color: Colors.green,
                  onTap: () => _pickFileByType(context, FileType.custom, allowedExtensions: ['xls', 'xlsx']),
                ),
                _buildFileTypeOption(
                  icon: Icons.slideshow,
                  label: 'PowerPoint',
                  color: Colors.orange,
                  onTap: () => _pickFileByType(context, FileType.custom, allowedExtensions: ['ppt', 'pptx']),
                ),
                _buildFileTypeOption(
                  icon: Icons.archive,
                  label: 'ZIP/RAR',
                  color: Colors.purple,
                  onTap: () => _pickFileByType(context, FileType.custom, allowedExtensions: ['zip', 'rar', '7z']),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFileTypeOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFileByType(BuildContext context, FileType type, {List<String>? allowedExtensions}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        onFileSelected(file);
        onClose();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçme hatası: $e')),
      );
    }
  }
}



