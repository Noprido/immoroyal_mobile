import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/colors.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: kGreyLight,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton d'une carte annonce
class AnnonceCardSkeleton extends StatelessWidget {
  const AnnonceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kGreyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniature
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: kGreyLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 200, color: kGreyLight),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 130, color: kGreyLight),
                  const SizedBox(height: 8),
                  Container(height: 18, width: 100, color: kGreyLight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste de skeletons
class AnnonceListSkeleton extends StatelessWidget {
  final int count;
  const AnnonceListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (_, __) => const AnnonceCardSkeleton(),
    );
  }
}

/// Skeleton Home
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En vedette — titre ──
            Container(height: 16, width: 100, color: kGreyLight),
            const SizedBox(height: 14),
            // ── En vedette — 3 cards horizontales simulées en Row ──
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  height: 180,
                  decoration: BoxDecoration(
                    color: kGreyLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            // ── Dernières annonces — titre ──
            Container(height: 16, width: 160, color: kGreyLight),
            const SizedBox(height: 14),
            // ── 3 cards verticales (image gauche + infos droite) ──
            ...List.generate(3, (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 100,
              decoration: BoxDecoration(
                color: kGreyLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 110,
                    decoration: const BoxDecoration(
                      color: kGreyBorder,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(height: 10, width: 60, color: kGreyBorder),
                          const SizedBox(height: 6),
                          Container(height: 13, width: double.infinity, color: kGreyBorder),
                          const SizedBox(height: 4),
                          Container(height: 13, width: 100, color: kGreyBorder),
                          const SizedBox(height: 8),
                          Container(height: 14, width: 80, color: kGreyBorder),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            // ── Grille 2 colonnes ──
            Container(height: 16, width: 180, color: kGreyLight),
            const SizedBox(height: 14),
            ...List.generate(2, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: List.generate(2, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 1 ? 12 : 0),
                    height: 180,
                    decoration: BoxDecoration(
                      color: kGreyLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Skeleton détail annonce
class AnnonceDetailSkeleton extends StatelessWidget {
  const AnnonceDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image principale
            Container(height: 300, width: double.infinity, color: kGreyLight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(children: [
                    Container(height: 24, width: 80, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(width: 8),
                    Container(height: 24, width: 80, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(6))),
                  ]),
                  const SizedBox(height: 12),
                  // Titre
                  Container(height: 22, width: double.infinity, color: kGreyLight),
                  const SizedBox(height: 8),
                  Container(height: 22, width: 200, color: kGreyLight),
                  const SizedBox(height: 12),
                  // Localisation
                  Container(height: 14, width: 150, color: kGreyLight),
                  const SizedBox(height: 12),
                  // Prix
                  Container(height: 28, width: 120, color: kGreyLight),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Section infos
                  Container(height: 16, width: 180, color: kGreyLight),
                  const SizedBox(height: 12),
                  Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Description
                  Container(height: 16, width: 120, color: kGreyLight),
                  const SizedBox(height: 12),
                  ...List.generate(3, (_) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: 14,
                    width: double.infinity,
                    color: kGreyLight,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton carte recherche (pour la liste)
class RechercheCardSkeleton extends StatelessWidget {
  const RechercheCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGreyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges
            Row(children: [
              Container(height: 22, width: 80, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 8),
              Container(height: 22, width: 70, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 8),
              Container(height: 22, width: 60, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(6))),
            ]),
            const SizedBox(height: 12),
            // Titre
            Container(height: 16, width: double.infinity, color: kGreyLight),
            const SizedBox(height: 6),
            Container(height: 16, width: 200, color: kGreyLight),
            const SizedBox(height: 12),
            // Localisation + budget
            Row(children: [
              Container(height: 12, width: 120, color: kGreyLight),
              const Spacer(),
              Container(height: 16, width: 90, color: kGreyLight),
            ]),
            const SizedBox(height: 12),
            // Auteur
            Row(children: [
              Container(height: 28, width: 28, decoration: BoxDecoration(color: kGreyLight, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(height: 12, width: 100, color: kGreyLight),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Liste de skeletons recherche
class RechercheListSkeleton extends StatelessWidget {
  final int count;
  const RechercheListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (_, __) => const RechercheCardSkeleton(),
    );
  }
}

/// Skeleton détail recherche
class RechercheDetailSkeleton extends StatelessWidget {
  const RechercheDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges
            Row(children: [
              Container(height: 24, width: 90, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 8),
              Container(height: 24, width: 80, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 8),
              Container(height: 24, width: 70, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(6))),
            ]),
            const SizedBox(height: 16),
            // Titre
            Container(height: 24, width: double.infinity, color: kGreyLight),
            const SizedBox(height: 8),
            Container(height: 24, width: 220, color: kGreyLight),
            const SizedBox(height: 8),
            Container(height: 12, width: 140, color: kGreyLight),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Section localisation
            Container(height: 14, width: 100, color: kGreyLight),
            const SizedBox(height: 12),
            Container(height: 14, width: double.infinity, color: kGreyLight),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Section budget
            Container(height: 14, width: 80, color: kGreyLight),
            const SizedBox(height: 12),
            Container(
              height: 52,
              decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Caractéristiques
            Container(height: 14, width: 180, color: kGreyLight),
            const SizedBox(height: 12),
            Row(children: List.generate(3, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                height: 72,
                decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(8)),
              ),
            ))),
          ],
        ),
      ),
    );
  }
}

/// Skeleton liste conversations
class ConversationListSkeleton extends StatelessWidget {
  const ConversationListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGreyBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(color: kGreyLight, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(height: 14, width: 120, color: kGreyLight),
                        Container(height: 12, width: 50, color: kGreyLight),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(height: 11, width: 160, color: kGreyLight),
                    const SizedBox(height: 6),
                    Container(height: 11, width: 200, color: kGreyLight),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton profil dashboard
class ProfilDashboardSkeleton extends StatelessWidget {
  const ProfilDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 180, color: kGreyLight),
            const SizedBox(height: 14),
            ...List.generate(3, (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 80,
              decoration: BoxDecoration(
                color: kGreyLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    decoration: const BoxDecoration(
                      color: kGreyBorder,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(height: 13, width: double.infinity, color: kGreyBorder),
                          const SizedBox(height: 6),
                          Container(height: 11, width: 120, color: kGreyBorder),
                          const SizedBox(height: 6),
                          Container(height: 13, width: 80, color: kGreyBorder),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}