import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CryptoLogo extends StatelessWidget {
  final String symbol;
  final double size;

  const CryptoLogo({
    super.key,
    required this.symbol,
    this.size = 38,
  });

  static const Map<String, String> _logoFiles = {
    'BTC': 'bitcoin.svg',
    'ETH': 'ethereum.svg',
    'TON': 'toncoin.svg',
    'SOL': 'solana.svg',
    'BNB': 'bnb.svg',
    'DOGE': 'dogecoin.svg',
    'ARB': 'arbitrum.svg',
    'AVAX': 'avalanche.svg',
    'BCH': 'bitcoin-cash.svg',
    'ETC': 'ethereum-classic.svg',
    'XMR': 'monero.svg',
    'SHIB': 'shiba-inu.svg',
  };



  static const Map<String, List<Color>> _gradients = {
    'BTC': [Color(0xFFF7931A), Color(0xFFFFAB40)],
    'ETH': [Color(0xFF627EEA), Color(0xFF8C9EFF)],
    'TON': [Color(0xFF0098EA), Color(0xFF80D8FF)],
    'SOL': [Color(0xFF14F195), Color(0xFF9945FF)],
    'BNB': [Color(0xFFF3BA2F), Color(0xFFFFD54F)],
    'DOGE': [Color(0xFFC2A633), Color(0xFFFFE082)],
    'ARB': [Color(0xFF28A0F0), Color(0xFF9BD4FC)],
    'AVAX': [Color(0xFFE84142), Color(0xFFFF8A8B)],
    'BCH': [Color(0xFF8DC351), Color(0xFFB9E185)],
    'ETC': [Color(0xFF348030), Color(0xFF76C371)],
    'XMR': [Color(0xFFFF6600), Color(0xFFFFAB40)],
    'SHIB': [Color(0xFFFFA000), Color(0xFFFFD54F)],
  };

  @override
  Widget build(BuildContext context) {
    final cleanSymbol = symbol.toUpperCase();
    final logoFile = _logoFiles[cleanSymbol];
    final gradient = _gradients[cleanSymbol] ?? [const Color(0xFF6B7280), const Color(0xFF9CA3AF)];

    if (logoFile == null) {
      return _buildFallback(cleanSymbol, gradient);
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        'logos/$logoFile',
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildFallback(cleanSymbol, gradient),
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading icon for $cleanSymbol: $error');
          return _buildFallback(cleanSymbol, gradient);
        },
      ),
    );
  }

  Widget _buildFallback(String sym, List<Color> gradient) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      alignment: Alignment.center,
      child: _buildFallbackText(sym),
    );
  }

  Widget _buildFallbackText(String sym) {
    return Text(
      sym.isNotEmpty ? sym[0] : '?',
      style: TextStyle(
        color: CupertinoColors.white,
        fontWeight: FontWeight.bold,
        fontSize: size * 0.45,
      ),
    );
  }
}
