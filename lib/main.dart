import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// l10n
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const Split2mApp());
}

class Split2mApp extends StatelessWidget {
  const Split2mApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppLocalizations.of(context)?.appTitle ?? '2分動画分割',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
      ],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  XFile? _videoFile;
  VideoPlayerController? _controller;
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _status;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        _controller?.dispose();
        _controller = VideoPlayerController.file(File(pickedFile.path));
        await _controller!.initialize();
        setState(() {
          _videoFile = pickedFile;
          _status = null;
        });
      } catch (e) {
        setState(() {
          _videoFile = null;
          _status = "${AppLocalizations.of(context)?.initPreviewFailed.replaceFirst('{error}', '$e') ?? "動画プレビューの初期化に失敗しました: $e"}";
        });
      }
    }
  }

  Future<void> _openPhotosApp() async {
    // iOS: photos-redirect://
    // Android: content://media/external/images/media/
    final url = Platform.isIOS ? 'photos-redirect://' : 'content://media/external/images/media/';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching photos app: $e');
    }
  }

  Future<void> _splitAndSaveVideo() async {
    if (_videoFile == null) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _status = AppLocalizations.of(context)?.processingStarted ?? "分割処理を開始します...";
    });

    // 権限確認
    if (!await _requestPermissions()) {
      setState(() {
        _isProcessing = false;
        _status = AppLocalizations.of(context)?.noPermission ?? "必要な権限がありません。";
      });
      return;
    }

    final file = File(_videoFile!.path);
    final dir = await getTemporaryDirectory();
    final tempDir = Directory('${dir.path}/split2m_temp');
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    tempDir.createSync();

    // 動画の長さ取得
    final duration = _controller!.value.duration.inSeconds;
    final segmentLength = 120;
    final segmentCount = (duration / segmentLength).ceil();
    final baseName = _videoFile!.name.split('.').first;

    for (int i = 0; i < segmentCount; i++) {
      final start = i * segmentLength;
      final outPath = '${tempDir.path}/${baseName}_part${i + 1}.mp4';
      final cmd =
          "-i \"${file.path}\" -ss $start -t $segmentLength -c copy \"$outPath\"";
      setState(() {
        _progress = (i + 1) / segmentCount;
        _status = AppLocalizations.of(context)?.processing
            .replaceFirst('{current}', '${i + 1}')
            .replaceFirst('{total}', '$segmentCount') ?? "分割中... (${i + 1}/$segmentCount)";
      });
      await FFmpegKit.execute(cmd);
      await GallerySaver.saveVideo(outPath);
    }

    // 一時ファイル削除
    tempDir.deleteSync(recursive: true);

    setState(() {
      _isProcessing = false;
      _progress = 1.0;
      _status = AppLocalizations.of(context)?.saved ?? "カメラロールに保存しました";
    });
  }

  Future<bool> _requestPermissions() async {
    // iOS 14+ では .photos, .photosAddOnly の両方を明示的にリクエスト
    final photosStatus = await Permission.photos.request();
    final addOnlyStatus = await Permission.photosAddOnly.request();

    // 権限状態をデバッグ出力
    debugPrint('Permission.photos: ${photosStatus.toString()}');
    debugPrint('Permission.photosAddOnly: ${addOnlyStatus.toString()}');

    if (photosStatus.isGranted || addOnlyStatus.isGranted) {
      return true;
    }

    // どちらも拒否されている場合はダイアログ表示
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.permissionRequiredTitle ?? '権限が必要です'),
        content: Text(AppLocalizations.of(context)?.permissionRequiredContent ?? '動画を保存するには「写真」へのフルアクセスまたは書き込み権限が必要です。設定から許可してください。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)?.cancel ?? 'キャンセル'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)?.openSettings ?? '設定を開く'),
          ),
        ],
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.appTitle ?? '2分動画分割'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickVideo,
                icon: const Icon(Icons.video_library, size: 28),
                label: Text(
                  AppLocalizations.of(context)?.pickVideo ?? '動画を選択',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_videoFile != null && _controller != null)
              Container(
                height: 300, // 固定の高さを設定
                width: double.infinity,
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            if (_videoFile != null && !_isProcessing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _splitAndSaveVideo,
                    icon: const Icon(Icons.cut, size: 28),
                    label: Text(
                      AppLocalizations.of(context)?.splitAndSave ?? '2分ごとに分割して保存',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            if (_isProcessing)
              Column(
                children: [
                  const SizedBox(height: 24),
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text(_status ?? ''),
                ],
              ),
            if (_status != null && !_isProcessing)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    Text(
                      _status!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_status == (AppLocalizations.of(context)?.saved ?? "カメラロールに保存しました"))
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _openPhotosApp,
                            icon: const Icon(Icons.photo_library, size: 24),
                            label: Text(
                              AppLocalizations.of(context)?.openCameraRoll ?? 'カメラロールを開く',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          ),
        ),
      ),
      floatingActionButton: (_controller != null && _videoFile != null)
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
              child: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}
