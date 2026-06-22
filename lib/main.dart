import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'image_loader.dart';

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
    return MaterialApp(
      title: 'Wallpaper Inc.',
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

  // Curated list of high-quality Picsum Photo IDs for zero-config fallback
  final List<int> _picsumIds = [
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50
  ];

  @override
  void initState() {
    super.initState();
    _generateTrendingWallpapers();
  }

  // Generate fallback wallpapers locally to avoid CORS errors on Flutter Web
  void _generateTrendingWallpapers() {
    setState(() {
      _trendingWallpapers = _picsumIds.map<Map<String, dynamic>>((id) {
        return {
          'id': id.toString(),
          'title': 'Aesthetic Visual #$id',
          'url': 'https://picsum.photos/id/$id/1080/1920',
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
      // Translucent custom iOS-style Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF1C1C1E), width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            setState(() {
              _currentBottomNavIndex = index;
              if (index == 0) {
                _selectedCategory = 'all';
              } else if (index == 1) {
                _selectedCategory = 'favorites';
              }
            });
          },
          backgroundColor: const Color(0xFF09090B),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 22),
              activeIcon: Icon(Icons.grid_view_rounded, size: 22),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded, size: 22),
              activeIcon: Icon(Icons.favorite_rounded, size: 22),
              label: 'Favorites',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Minimalist Top Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EXPLORE',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B), // Zinc-900
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A), width: 1.0),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 20),
                    )
                  ],
                ),
              ),
            ),

            // "Wallpaper of the Day" / Featured Banner (Minimal style, no text overlay clutter)
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
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
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF27272A), width: 1.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: SafeImage(
                              url: featuredWallpaperUrl,
                              fit: BoxFit.cover,
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
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: staticCategories.length + 1, // 'All' + static categories
                      itemBuilder: (context, index) {
                        String id = 'all';
                        String name = 'All';

                        if (index == 0) {
                          id = 'all';
                          name = 'All';
                        } else {
                          final cat = staticCategories[index - 1];
                          id = cat['id']!;
                          name = cat['name']!;
                        }

                        final isSelected = _selectedCategory == id;

                        return GestureDetector(
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
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.white : const Color(0xFF27272A),
                                width: 1.0,
                              ),
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
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                  MaterialPageRoute(
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
              const SliverToBoxAdapter(
                child: SizedBox(height: 30),
              )
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
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Original High Resolution Wallpaper',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                // Premium Minimal Button (Pure White / Black Text)
                GestureDetector(
                  onTap: () => _downloadImage(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'DOWNLOAD WALLPAPER',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
