import 'package:flutter/material.dart';

class FileMessageWidget extends StatelessWidget {
  final String fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? fileExtension;
  final bool isMe;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileMessageWidget({
    super.key,
    required this.fileName,
    this.fileUrl,
    this.fileSize,
    this.fileExtension,
    required this.isMe,
    this.onTap,
    this.onLongPress,
  });

  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String? extension) {
    if (extension == null) return Colors.grey;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue[700]!;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.purple;
      case 'txt':
        return Colors.grey[700]!;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.pink;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.indigo;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int? size) {
    if (size == null) return 'Bilinmeyen boyut';
    
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileIcon = _getFileIcon(fileExtension);
    final fileColor = _getFileColor(fileExtension);
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe 
              ? Colors.deepPurple[500] 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe 
                ? Colors.deepPurple.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // File icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMe 
                    ? Colors.white.withValues(alpha: 0.2)
                    : fileColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                fileIcon,
                color: isMe ? Colors.white : fileColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File name
                  Text(
                    fileName,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // File size and extension
                  Row(
                    children: [
                      Text(
                        _formatFileSize(fileSize),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (fileExtension != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMe 
                                ? Colors.white.withValues(alpha: 0.2)
                                : fileColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            fileExtension!.toUpperCase(),
                            style: TextStyle(
                              color: isMe ? Colors.white70 : fileColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Download/Open icon
            Icon(
              fileUrl != null ? Icons.download : Icons.upload,
              color: isMe ? Colors.white70 : Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}



