import 'package:flutter/material.dart';
import '../theme/eco_theme.dart';
import 'login_view.dart';
import 'register_view.dart';
import 'solicitud_operador_view.dart'; // <-- IMPORTACIÓN AGREGADA

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 800;

    return Scaffold(
      backgroundColor: EcoTheme.warmCream,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // =========================================================================
            // 1. HERO SECTOR ANIMADO
            // =========================================================================
            Stack(
              children: [
                SizedBox(
                  height: isDesktop ? 600 : 500,
                  width: double.infinity,
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 1.0, end: 1.1),
                    duration: const Duration(seconds: 25),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1533105079780-92b9be482077?q=80&w=1374&auto=format&fit=crop',
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  height: isDesktop ? 600 : 500,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        EcoTheme.darkForest.withOpacity(0.95),
                        Colors.black.withOpacity(0.1),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                color: EcoTheme.ecoGold,
                                size: 36,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'EcoRutas Vzla',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(0, 40 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Explora Venezuela\nde Forma Sustentable',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isDesktop ? 52 : 36,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'Descubre senderos mágicos, gestiona permisos institucionales\ny únete a la red universitaria de ecoturismo.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: EcoTheme.warmCream.withOpacity(
                                            0.9,
                                          ),
                                          fontSize: isDesktop ? 20 : 16,
                                        ),
                                      ),
                                      const SizedBox(height: 50),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // =========================================================================
            // 2. TARJETA FLOTANTE DE ACCESOS (CON BOTÓN DE OPERADOR)
            // =========================================================================
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutBack,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 650),
                    padding: const EdgeInsets.all(32.0),
                    decoration: EcoTheme.luxuryCard(),
                    child: Column(
                      children: [
                        const Text(
                          '¿Listo para comenzar tu aventura verde?',
                          style: TextStyle(
                            color: EcoTheme.darkForest,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginView(),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: EcoTheme.forestGreen,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'INICIAR SESIÓN',
                                  style: TextStyle(
                                    color: EcoTheme.forestGreen,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterView(),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EcoTheme.forestGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'REGISTRARSE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // =========================================================================
                        // ENLACE: SOLICITAR SER OPERADOR (AGREGADO)
                        // =========================================================================
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SolicitudOperadorView(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: EcoTheme.forestGreen,
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: '¿Quieres trabajar con nosotros? ',
                              style: TextStyle(
                                color: EcoTheme.softGray,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Solicita ser operador aquí',
                                  style: TextStyle(
                                    color: EcoTheme.forestGreen,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // =========================================================================
            // 3. SECCIÓN DE OFERTAS Y SERVICIOS
            // =========================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Text(
                    'Descubre la Experiencia EcoRutas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EcoTheme.darkForest,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Todo lo que necesitas para tu viaje universitario, centralizado en una plataforma inteligente y amigable con el planeta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EcoTheme.softGray, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: const [
                      ServiceImageCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800&auto=format&fit=crop',
                        title: 'Destinos Protegidos',
                        description:
                            'Explora un catálogo extenso de rutas validadas por expertos, con mapas detallados y niveles de dificultad.',
                      ),
                      ServiceImageCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=800&auto=format&fit=crop',
                        title: 'Guías y Operadores',
                        description:
                            'Conecta con prestadores de servicios certificados y estudiantes guías que enriquecerán tu experiencia.',
                      ),
                      ServiceImageCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=800&auto=format&fit=crop',
                        title: 'Gestión de Permisos',
                        description:
                            'Sube avales, firma acuerdos de responsabilidad y gestiona todo el papeleo institucional digitalmente.',
                      ),
                      ServiceImageCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1466611653911-95081537e5b7?q=80&w=800&auto=format&fit=crop',
                        title: 'Impacto y Métricas',
                        description:
                            'Mide tu huella de carbono, registra tus expediciones y contribuye a las estadísticas de conservación ambiental.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),

            // Footer Estético
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              color: EcoTheme.darkForest,
              child: const Column(
                children: [
                  Icon(Icons.eco, color: EcoTheme.ecoGold, size: 30),
                  SizedBox(height: 10),
                  Text(
                    '© 2024 EcoRutas Venezuela',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Desarrollado para la Universidad Metropolitana',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceImageCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;

  const ServiceImageCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  @override
  State<ServiceImageCard> createState() => _ServiceImageCardState();
}

class _ServiceImageCardState extends State<ServiceImageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 280,
          height: 380,
          transform: Matrix4.translationValues(0, _isHovered ? -12 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? EcoTheme.forestGreen.withOpacity(0.4)
                    : Colors.black.withOpacity(0.15),
                blurRadius: _isHovered ? 25 : 10,
                offset: Offset(0, _isHovered ? 15 : 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  child: Image.network(widget.imageUrl, fit: BoxFit.cover),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(_isHovered ? 0.85 : 0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          transform: Matrix4.translationValues(
                            0,
                            _isHovered ? 10 : 25,
                            0,
                          ),
                          child: Text(
                            widget.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
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
      ),
    );
  }
}
