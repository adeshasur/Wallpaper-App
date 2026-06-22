import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'image_loader.dart';
import 'bounceable.dart';

// Firebase configuration using existing keys
const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDjffxaZJ7vmAlzA-LnN0Vhlh3EBJ4uRqE",
  authDomain: "wallpaper-incc.firebaseapp.com",
  projectId: "wallpaper-incc",
  storageBucket: "wallpaper-incc.appspot.com",
  messagingSenderId: "795698360511",
  appId: "1:795698360511:web:af7e54ac8e2f410a6ad60a",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const WallpaperApp());
}

class WallpaperApp extends StatelessWidget {
  const WallpaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData(brightness: Brightness.dark).textTheme;
    return MaterialApp(
      title: 'AuraWall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B), // Zinc-950 (iOS style dark)
        primaryColor: Colors.white,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFFE4E4E7), // Zinc-200
          surface: Color(0xFF18181B), // Zinc-900
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.outfitTextTheme(baseTextTheme),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// Fallback Curated Categories using Unsplash links
final List<Map<String, String>> staticCategories = [
  {
    'id': 'nature',
    'name': 'Nature',
    'thumbnail': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=500&auto=format&fit=crop&q=60',
  },
  {
    'id': 'space',
    'name': 'Space',
    'thumbnail': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=500&auto=format&fit=crop&q=60',
  },
  {
    'id': 'cars',
    'name': 'Cars',
    'thumbnail': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=500&auto=format&fit=crop&q=60',
  },
  {
    'id': 'minimal',
    'name': 'Minimal',
    'thumbnail': 'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=500&auto=format&fit=crop&q=60',
  },
];

// Fallback Curated Wallpapers per category
final Map<String, List<Map<String, String>>> fallbackWallpapersByCategory = {
  'nature': [
    {
      'title': 'Green Forests',
      'url': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Mountain Sunrise',
      'url': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Sea Waves',
      'url': 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=1080&auto=format&fit=crop&q=80',
    },
  ],
  'space': [
    {
      'title': 'Deep Nebula',
      'url': 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Spiral Galaxy',
      'url': 'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Blue Earth',
      'url': 'https://images.unsplash.com/photo-1614730321146-b6fa6a46bcb4?w=1080&auto=format&fit=crop&q=80',
    },
  ],
  'cars': [
    {
      'title': 'Retro Porsche',
      'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Neon Sportscar',
      'url': 'https://images.unsplash.com/photo-1525609004556-c46c7d6cf0a3?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Offroad Mustang',
      'url': 'https://images.unsplash.com/photo-1611245801311-66df9892c906?w=1080&auto=format&fit=crop&q=80',
    },
  ],
  'minimal': [
    {
      'title': 'Aesthetic Plant',
      'url': 'https://images.unsplash.com/photo-1494438639946-1ebd1d2038b5?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Warm Geometry',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Pastel Dunes',
      'url': 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?w=1080&auto=format&fit=crop&q=80',
    },
  ],
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _trendingWallpapers = [];
  final List<String> _favoriteUrls = [];
  String _selectedCategory = 'all';
  int _currentBottomNavIndex = 0;

  // Curated list of high-quality verified Unsplash wallpaper URLs for zero-config fallback
  final List<Map<String, String>> _unsplashTrendingWallpapers = [
    {
      'title': 'Golden Beach Sunrise',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Mist Forest Path',
      'url': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Futuristic Network',
      'url': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Vintage Ride',
      'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Pastel Horizon',
      'url': 'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Mountain Ridge',
      'url': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Gentle Waves',
      'url': 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Orion Nebula',
      'url': 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Milky Way Galaxy',
      'url': 'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Planet Earth',
      'url': 'https://images.unsplash.com/photo-1614730321146-b6fa6a46bcb4?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Supercar Silhouette',
      'url': 'https://images.unsplash.com/photo-1525609004556-c46c7d6cf0a3?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Modern Mustang',
      'url': 'https://images.unsplash.com/photo-1611245801311-66df9892c906?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Minimal Desk Lamp',
      'url': 'https://images.unsplash.com/photo-1494438639946-1ebd1d2038b5?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Pastel Dunes',
      'url': 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?w=1080&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateTrendingWallpapers();
  }

  // Generate fallback wallpapers locally using verified Unsplash URLs
  void _generateTrendingWallpapers() {
    setState(() {
      _trendingWallpapers = _unsplashTrendingWallpapers.map<Map<String, dynamic>>((wp) {
        return {
          'id': wp['title']!,
          'title': wp['title']!,
          'url': wp['url']!,
          'categoryId': 'trending',
        };
      }).toList();
    });
  }

  void _toggleFavorite(String url) {
    setState(() {
      if (_favoriteUrls.contains(url)) {
        _favoriteUrls.remove(url);
      } else {
        _favoriteUrls.add(url);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final featuredWallpaperUrl = _trendingWallpapers.isNotEmpty ? _trendingWallpapers[0]['url'] : '';
    final featuredTitle = _trendingWallpapers.isNotEmpty ? _trendingWallpapers[0]['title'] : '';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Glassmorphic Pinned iOS-style Header
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                toolbarHeight: 80, // Height of the nav bar including status bar safety padding
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                    child: Container(
                      color: const Color(0xFF09090B).withValues(alpha: 0.8),
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 28.0),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Aura',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Wall',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.5,
                                    color: Colors.white70,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' •',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Bounceable(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => ProfileScreen(
                                    favoriteCount: _favoriteUrls.length,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B), // Zinc-900
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF27272A), width: 1.0),
                              ),
                              child: const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

                // "Wallpaper of the Day" / Featured Banner (Premium glass showcase style)
                if (_currentBottomNavIndex == 0 && featuredWallpaperUrl.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WALLPAPER OF THE DAY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Bounceable(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => WallpaperViewScreen(
                                    imageUrl: featuredWallpaperUrl,
                                    title: featuredTitle,
                                    isFavorite: _favoriteUrls.contains(featuredWallpaperUrl),
                                    onFavoriteToggle: () => _toggleFavorite(featuredWallpaperUrl),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 240,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.18), // Violet ambient glow
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(23),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: SafeImage(
                                        url: featuredWallpaperUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.4),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            color: Colors.black.withValues(alpha: 0.4),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                                SizedBox(width: 4),
                                                Text(
                                                  'FEATURED',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Minimal Category horizontal chips list
                if (_currentBottomNavIndex == 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                      child: SizedBox(
                        height: 38,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('categories').snapshots(),
                          builder: (context, snapshot) {
                            List<Map<String, String>> categories = [];
                            
                            // Add static ones first
                            for (var cat in staticCategories) {
                              categories.add({
                                'id': cat['id']!,
                                'name': cat['name']!,
                              });
                            }
                            
                            // Add firestore ones (avoiding duplicates by normalized ID)
                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              for (var doc in snapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['name']?.toString() ?? '';
                                final id = name.toLowerCase().trim();
                                if (name.isNotEmpty && !categories.any((c) => c['id'] == id)) {
                                  categories.add({
                                    'id': id,
                                    'name': name,
                                  });
                                }
                              }
                            }

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              itemCount: categories.length + 1, // 'All' + dynamic categories
                              itemBuilder: (context, index) {
                                String id = 'all';
                                String name = 'All';

                                if (index == 0) {
                                  id = 'all';
                                  name = 'All';
                                } else {
                                  final cat = categories[index - 1];
                                  id = cat['id']!;
                                  name = cat['name']!;
                                }

                                final isSelected = _selectedCategory == id;

                                return Bounceable(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = id;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : const Color(0xFF18181B),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? Colors.white : const Color(0xFF27272A),
                                        width: 1.0,
                                      ),
                                      boxShadow: isSelected ? [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ] : null,
                                    ),
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.grey[400],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        ),
                      ),
                    ),
                  ),

                // Grid section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 24.0, bottom: 12.0),
                    child: Text(
                      _currentBottomNavIndex == 1
                          ? 'FAVORITE WALLPAPERS'
                          : 'ALL COLLECTIONS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                // Clean Image Grid (Pure visual cards, no clutter, no texts)
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('wallpapers').snapshots(),
                  builder: (context, snapshot) {
                    List<Map<String, dynamic>> wallpapers = [];

                    // Gather Firestore database wallpapers
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        wallpapers.add({
                          'id': doc.id,
                          'url': data['url'] ?? '',
                          'title': data['title'] ?? 'Wallpaper',
                          'categoryId': data['categoryId'] ?? 'all',
                        });
                      }
                    }

                    // Filter logic
                    if (_selectedCategory == 'favorites' || _currentBottomNavIndex == 1) {
                      wallpapers = _trendingWallpapers
                          .where((wp) => _favoriteUrls.contains(wp['url']))
                          .toList();
                    } else if (_selectedCategory != 'all') {
                      final dbFiltered = wallpapers
                          .where((wp) => wp['categoryId'].toString().toLowerCase() == _selectedCategory.toLowerCase())
                          .toList();

                      if (dbFiltered.isEmpty) {
                        final fallback = fallbackWallpapersByCategory[_selectedCategory] ?? [];
                        wallpapers = fallback.map((wp) => {
                          'id': wp['title']!,
                          'url': wp['url']!,
                          'title': wp['title']!,
                          'categoryId': _selectedCategory,
                        }).toList();
                      } else {
                        wallpapers = dbFiltered;
                      }
                    } else {
                      if (wallpapers.isEmpty) {
                        wallpapers = _trendingWallpapers;
                      }
                    }

                    if (wallpapers.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No wallpapers found.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final wp = wallpapers[index];
                            final url = wp['url'] ?? '';
                            final title = wp['title'] ?? 'Wallpaper';
                            final isFav = _favoriteUrls.contains(url);

                            return Hero(
                              tag: url,
                              child: Bounceable(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (_) => WallpaperViewScreen(
                                        imageUrl: url,
                                        title: title,
                                        isFavorite: isFav,
                                        onFavoriteToggle: () => _toggleFavorite(url),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF1C1C1E), width: 1.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Container(
                                      color: const Color(0xFF18181B),
                                      child: url.isNotEmpty
                                          ? SafeImage(
                                              url: url,
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(child: Icon(Icons.image)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: wallpapers.length,
                        ),
                      ),
                    );
                  },
                ),
                
                // Bottom padding to ensure content can scroll past the floating navigation bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),

          // Floating Glassmorphic Bottom Navigation Bar
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090B).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFloatingNavItem(
                        index: 0,
                        iconOutlined: Icons.grid_view_outlined,
                        iconFilled: Icons.grid_view_rounded,
                        label: 'Explore',
                      ),
                      _buildFloatingNavItem(
                        index: 1,
                        iconOutlined: Icons.favorite_outline_rounded,
                        iconFilled: Icons.favorite_rounded,
                        label: 'Favorites',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required int index,
    required IconData iconOutlined,
    required IconData iconFilled,
    required String label,
  }) {
    final isSelected = _currentBottomNavIndex == index;
    return Bounceable(
      scaleFactor: 0.92,
      onTap: () {
        setState(() {
          _currentBottomNavIndex = index;
          if (index == 0) {
            _selectedCategory = 'all';
          } else if (index == 1) {
            _selectedCategory = 'favorites';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? Colors.white : Colors.grey[500],
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[500],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WallpaperViewScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const WallpaperViewScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  State<WallpaperViewScreen> createState() => _WallpaperViewScreenState();
}

class _WallpaperViewScreenState extends State<WallpaperViewScreen> {
  late bool _isFavoriteLocal;

  @override
  void initState() {
    super.initState();
    _isFavoriteLocal = widget.isFavorite;
  }

  List<Color> _getWallpaperPalette(String title) {
    final int hash = title.hashCode;
    final Color c1 = HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.6, 0.4).toColor();
    final Color c2 = HSLColor.fromAHSL(1.0, ((hash + 40) % 360).toDouble(), 0.5, 0.5).toColor();
    final Color c3 = HSLColor.fromAHSL(1.0, ((hash + 80) % 360).toDouble(), 0.6, 0.6).toColor();
    final Color c4 = HSLColor.fromAHSL(1.0, ((hash + 180) % 360).toDouble(), 0.4, 0.7).toColor();
    final Color c5 = HSLColor.fromAHSL(1.0, ((hash + 220) % 360).toDouble(), 0.5, 0.3).toColor();
    return [c1, c2, c3, c4, c5];
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading wallpaper...'),
          duration: Duration(seconds: 2),
        ),
      );

      final response = await http.get(Uri.parse(widget.imageUrl));
      final bytes = response.bodyBytes;

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/wallpaper_$timestamp.jpg');
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to app storage successfully! File: wallpaper_$timestamp.jpg'),
          backgroundColor: Colors.white,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black45,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black45,
            ),
            child: IconButton(
              icon: Icon(
                _isFavoriteLocal ? Icons.favorite : Icons.favorite_border,
                color: _isFavoriteLocal ? Colors.redAccent : Colors.white,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isFavoriteLocal = !_isFavoriteLocal;
                });
                widget.onFavoriteToggle();
              },
            ),
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: widget.imageUrl,
            child: SafeImage(
              url: widget.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Subtle shading gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
                        ),
                        child: const Text(
                          'ORIGINAL ART',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Specifications Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSpecItem(Icons.aspect_ratio_rounded, 'Resolution', '1440x3200'),
                          _buildSpecItem(Icons.sd_storage_rounded, 'Size', '2.4 MB'),
                          _buildSpecItem(Icons.image_search_rounded, 'Type', 'JPG'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Color Palette Header
                      const Text(
                        'COLOR PALETTE',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Color Palette Row
                      Row(
                        children: _getWallpaperPalette(widget.title).map((color) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      
                      // Download Button
                      Bounceable(
                        onTap: () => _downloadImage(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'DOWNLOAD WALLPAPER',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final int favoriteCount;

  const ProfileScreen({super.key, required this.favoriteCount});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _amoledMode = true;
  String _selectedQuality = 'High Resolution';
  double _cacheSize = 15.4;

  void _clearCache() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear temporary image caches?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              setState(() {
                _cacheSize = 0.0;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Temporary caches cleared successfully!'),
                  backgroundColor: Colors.white,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showQualitySelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.white,
        ),
        child: CupertinoActionSheet(
          title: const Text(
            'DOWNLOAD QUALITY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            _buildCupertinoQualityOption('Original (UHD 4K)'),
            _buildCupertinoQualityOption('High Resolution'),
            _buildCupertinoQualityOption('Medium (Data Saver)'),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoQualityOption(String quality) {
    final isSelected = _selectedQuality == quality;
    return CupertinoActionSheetAction(
      onPressed: () {
        setState(() {
          _selectedQuality = quality;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              quality,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_alt,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A), width: 1.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    blurRadius: 25,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Avatar with glow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF27272A),
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username
                  const Text(
                    'Wallpaper Enthusiast',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  
                  // Join Date
                  const Text(
                    'Member since June 2026',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  
                  // Member Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'PRO MEMBER',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF27272A), width: 1.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${widget.favoriteCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Favorites', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF27272A), width: 1.0),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '12',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Downloads', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Settings Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'APPLICATION SETTINGS',
                  style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),

            // Settings Tiles
            _buildSettingTile(
              icon: Icons.dark_mode_rounded,
              title: 'AMOLED Dark Mode',
              subtitle: 'Optimise layout contrast for OLED screens',
              trailing: CupertinoSwitch(
                value: _amoledMode,
                activeTrackColor: Colors.white,
                inactiveTrackColor: const Color(0xFF27272A),
                onChanged: (val) {
                  setState(() {
                    _amoledMode = val;
                  });
                },
              ),
            ),
            
            _buildSettingTile(
              icon: Icons.high_quality_rounded,
              title: 'Download Quality',
              subtitle: _selectedQuality,
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: _showQualitySelector,
            ),
            
            _buildSettingTile(
              icon: Icons.delete_sweep_rounded,
              title: 'Clear Caches',
              subtitle: 'Temporary files: ${_cacheSize.toStringAsFixed(1)} MB',
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: _clearCache,
            ),
            
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'Wallpaper.Inc v1.2.0',
              subtitle: 'Designed with love by Tunix',
            ),
          ],
        ),
      ),
    );
  }
}
