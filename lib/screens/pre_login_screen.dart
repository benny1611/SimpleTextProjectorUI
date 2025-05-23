import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PreLoginScreen extends StatelessWidget {
  const PreLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Login'), automaticallyImplyLeading: false,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login', arguments: {'mode': 'text'});
              },
              child: Text(AppLocalizations.of(context)!.enter_text),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login', arguments: {'mode': 'qr'});
              },
              child: Text(AppLocalizations.of(context)!.scan_qr),
            ),
          ],
        ),
      ),
    );
  }
}
