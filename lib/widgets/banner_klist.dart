import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerKList extends StatefulWidget {
  const BannerKList({super.key});

  @override
  State<BannerKList> createState() => _BannerKListState();
}

class _BannerKListState extends State<BannerKList> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // ⚠️ ID DE PRUEBA DE GOOGLE (¡NO USES EL TUYO AÚN!)
  // Este ID siempre muestra anuncios de prueba y protege tu cuenta.
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // ID Genérico de Android
      : 'ca-app-pub-3940256099942544/2934735716'; // ID Genérico de iOS

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner, // Tamaño estándar
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Si no carga, no mostramos nada (espacio vacío)
    return const SizedBox.shrink();
  }
}