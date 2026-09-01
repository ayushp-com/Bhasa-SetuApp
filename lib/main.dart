import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const PalashMTBMLEApp());
}

class PalashMTBMLEApp extends StatelessWidget {
  const PalashMTBMLEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PALASH MTB-MLE Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TranslationHomeScreen(),
    );
  }
}

class TranslationHomeScreen extends StatefulWidget {
  const TranslationHomeScreen({super.key});

  @override
  State<TranslationHomeScreen> createState() => _TranslationHomeScreenState();
}

class _TranslationHomeScreenState extends State<TranslationHomeScreen> {
  String selectedTargetLanguage = 'Santhali';
  String selectedSourceLanguage = 'Hindi'; 
  final TextEditingController _inputController = TextEditingController();
  String _translatedOutput = '';
  
  bool _isPlayingAudio = false;

  // STT Variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  final List<String> targetLanguages = ['Santhali', 'Mundari', 'Ho'];
  final List<String> sourceLanguages = ['Hindi', 'English']; 

  final GoogleTranslator aiTranslator = GoogleTranslator();
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == 'notListening' || val == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          print('onError: $val');
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _translatedOutput = "Listening... Speak now...";
        });
        
        String localeId = selectedSourceLanguage == 'Hindi' ? 'hi_IN' : 'en_US';

        _speech.listen(
          onResult: (val) {
            setState(() {
              _lastWords = val.recognizedWords;
              _inputController.text = _lastWords;
              _translate();
            });
          },
          localeId: localeId,
        );
      } else {
        setState(() {
          _isListening = false;
          _translatedOutput = "Speech recognition unavailable on this device.";
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _initTts() async {
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.45); 
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      setState(() => _isPlayingAudio = false);
    });

    flutterTts.setErrorHandler((msg) {
      setState(() => _isPlayingAudio = false);
      print("TTS Error: $msg");
    });
  }

  void _speakTranslation() async {
    if (_translatedOutput.isEmpty || _translatedOutput == 'Translating...') return;

    setState(() => _isPlayingAudio = true);

    String textToSpeak = _translatedOutput;
    
    final RegExp regExp = RegExp(r'\((.*?)\)');
    final matches = regExp.allMatches(_translatedOutput);
    
    if (matches.isNotEmpty) {
      textToSpeak = matches.map((m) => m.group(1)).join(' ');
      await flutterTts.setLanguage('en-US'); 
    } else {
      await flutterTts.setLanguage('hi-IN'); 
    }

    var result = await flutterTts.speak(textToSpeak);
    
    if (result != 1) {
      setState(() => _isPlayingAudio = false);
    }
  }

  void _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() => _translatedOutput = '');
      return;
    }

    setState(() => _translatedOutput = 'Translating...');

    List<String> words = text.split(' ');
    List<String> translatedWords = [];
    String sourceCode = selectedSourceLanguage == 'English' ? 'en' : 'hi';

    for (String w in words) {
      String? dbTranslation = await DatabaseHelper.instance.translateWord(w, selectedTargetLanguage, selectedSourceLanguage);
      
      if (dbTranslation != null) {
        translatedWords.add(dbTranslation);
      } else {
        try {
          if (selectedTargetLanguage == 'Santhali') {
            var aiTranslation = await aiTranslator.translate(w, from: sourceCode, to: 'sat');
            translatedWords.add(aiTranslation.text);
          } else {
            translatedWords.add("[$w]");
          }
        } catch (e) {
          translatedWords.add(w);
        }
      }
    }

    setState(() {
      _translatedOutput = translatedWords.join(' ');
    });
  }

  void _generateWorksheet() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'PALASH MTB-MLE: FLN Bilingual Worksheet'),
              pw.Paragraph(text: 'Target Language: $selectedTargetLanguage | Level: Grade 1-2 Foundational'),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['$selectedSourceLanguage (Teacher)', '$selectedTargetLanguage (Student)', 'Activity / Response'],
                  <String>['पानी / water', 'Daag / Da', '[  ] Match with picture'],
                  <String>['किताब / book', 'Potob / Puthi', '[  ] Read aloud'],
                  <String>['पेड़ / tree', 'Dare / Daru', '[  ] Draw the object'],
                  <String>['एक / one', 'Mit / Miyaad', '[  ] Count fingers'],
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  void dispose() {
    flutterTts.stop();
    _speech.cancel();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('PALASH MTB-MLE Bridge'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generateWorksheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: selectedSourceLanguage,
                      items: sourceLanguages.map((lang) {
                        return DropdownMenuItem(value: lang, child: Text('$lang Input', style: const TextStyle(fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSourceLanguage = val!;
                          _translate();
                        });
                      },
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    DropdownButton<String>(
                      value: selectedTargetLanguage,
                      items: targetLanguages.map((lang) {
                        return DropdownMenuItem(value: lang, child: Text('$lang Output', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedTargetLanguage = val!;
                          _translate();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teacher Input ($selectedSourceLanguage)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: selectedSourceLanguage == 'Hindi' ? 'उदा. किताब पढ़ना...' : 'e.g. read book...',
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => _translate(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$selectedTargetLanguage Output', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                        IconButton(
                          icon: Icon(
                            _isPlayingAudio ? Icons.volume_up : Icons.volume_up_outlined,
                            color: Colors.amber.shade900,
                          ),
                          tooltip: 'Speak Aloud (TTS)',
                          onPressed: _speakTranslation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _translatedOutput.isEmpty ? 'Translation will appear here...' : _translatedOutput,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _listen,
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  label: Text(_isListening ? 'Listening...' : 'Push to Talk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _speakTranslation,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Pronounce'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}