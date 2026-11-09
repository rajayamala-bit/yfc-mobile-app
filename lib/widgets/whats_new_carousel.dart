import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/content_service.dart';
import '../services/news_feed_service.dart';
import '../theme/app_theme.dart';

class WhatsNewCarousel extends StatefulWidget {
  final bool isTelugu;
  const WhatsNewCarousel({super.key, required this.isTelugu});

  @override
  State<WhatsNewCarousel> createState() => _WhatsNewCarouselState();
}

class _WhatsNewCarouselState extends State<WhatsNewCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  List<NewsItem> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadNewsFeed();
  }

  Future<void> _loadNewsFeed() async {
    final news = await NewsFeedService.getWhatsNew();
    if (mounted) {
      setState(() {
        _newsList = news;
        _isLoading = false;
      });
      if (_newsList.length > 1) {
        _startAutoSlide();
      }
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_newsList.isEmpty) return;
      _currentPage = (_currentPage + 1) % _newsList.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _openArticleLink(String linkUrl) async {
    final uri = Uri.parse(linkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showArticleDetails(BuildContext context, NewsItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0B132B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: item.imageUrl.startsWith('assets/')
                        ? Image.asset(
                            item.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            item.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/carousel/jerusalem.jpg',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.shiningRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: AppTheme.goldAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: GoogleFonts.cinzel(
                      color: isDark ? AppTheme.textLight : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${item.sourceName} • ${item.pubDate}",
                    style: TextStyle(
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    ContentService.sanitizeText(item.fullContent),
                    style: TextStyle(
                      color: isDark ? AppTheme.textLight : Colors.black87,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (item.link.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openArticleLink(item.link),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.shiningRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text(
                          "Read Full Story on Israel365 →",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B132B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.goldAccent),
        ),
      );
    }

    if (_newsList.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _newsList.length,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
            },
            itemBuilder: (context, index) {
              final item = _newsList[index];

              return InkWell(
                onTap: () => _showArticleDetails(context, item),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B132B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shiningRed.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: item.imageUrl.startsWith('assets/')
                            ? Image.asset(
                                item.imageUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                item.imageUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'assets/images/carousel/jerusalem.jpg',
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD90429),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    item.pubDate,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cinzel(
                                color: isDark ? AppTheme.textLight : const Color(0xFF000000),
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_newsList.length, (idx) {
            final isSelected = idx == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: isSelected ? 22 : 6,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldAccent : AppTheme.goldAccent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
